module Documents
  module Jobs
    class GenerateDocumentEmbeddingJob < BaseSidekiqJob
      sidekiq_options queue: :embeddings_queue, retry: true

      def initialize
        super
        @openai_client = Openai::Services::ClientService.instance
        @chunking_service = Documents::Services::TextChunkingService.instance
      end

      def perform(document_id)
        document = Documents::Models::Document.find_by(id: document_id)
        return unless document&.can_generate_embeddings?

        Rails.logger.info "Starting embedding generation for document #{document.id}: #{document.title}"

        begin
          # Clear existing embeddings if any
          document.document_embeddings.destroy_all

          # Split content into optimized chunks
          chunk_data = @chunking_service.chunk_text(document.content)

          if chunk_data.empty?
            handle_empty_chunks(document)
            return
          end

          successful_chunks = 0
          chunk_data.each do |chunk_info|
            begin
              # Generate embedding using centralized OpenAI service
              embedding = @openai_client.generate_embeddings(chunk_info[:content])

              if embedding.present?
                # Store embedding with enhanced metadata
                document.document_embeddings.create!(
                  content_chunk: chunk_info[:content],
                  embedding_vector: embedding,
                  chunk_index: chunk_info[:index],
                  token_count: chunk_info[:token_count],
                  metadata: {
                    chunk_size: chunk_info[:character_count],
                    chunk_index: chunk_info[:index],
                    embedding_model: Openai::Services::ClientService::EMBEDDING_MODEL,
                    generated_at: Time.current.iso8601
                  }
                )
                successful_chunks += 1
              else
                Rails.logger.warn "Failed to generate embedding for chunk #{chunk_info[:index]} of document #{document.id}"
              end

              # Add small delay to avoid rate limits
              sleep(0.1) if chunk_data.length > 10

            rescue => e
              Rails.logger.error "Error processing chunk #{chunk_info[:index]} for document #{document_id}: #{e.message}"
              # Continue with other chunks instead of failing completely
            end
          end

          if successful_chunks > 0
            document.update!(
              status: :processed,
              metadata: (document.metadata || {}).merge(
                "embedding_stats" => {
                  "total_chunks" => chunk_data.length,
                  "successful_chunks" => successful_chunks,
                  "failed_chunks" => chunk_data.length - successful_chunks,
                  "embedding_model" => Openai::Services::ClientService::EMBEDDING_MODEL,
                  "completed_at" => Time.current.iso8601
                }
              )
            )

            Rails.logger.info "Generated #{successful_chunks}/#{chunk_data.length} embeddings for document #{document.id}"
          else
            handle_embedding_failure(document, "No embeddings were successfully generated")
          end

        rescue => e
          Rails.logger.error "Embedding generation failed for document #{document_id}: #{e.message}"
          handle_embedding_failure(document, e.message, e.class.name)
        end
      end

      def handle_empty_chunks(document)
        document.update!(
          status: :failed,
          metadata: (document.metadata || {}).merge(
            "last_error" => {
              "step" => "embedding_generation",
              "message" => "No content chunks were generated from document text",
              "occurred_at" => Time.current.iso8601
            }
          )
        )
      end

      def handle_embedding_failure(document, message, error_class = nil)
        error_info = {
          "step" => "embedding_generation",
          "message" => message,
          "occurred_at" => Time.current.iso8601
        }
        error_info["error_class"] = error_class if error_class

        document.update!(
          status: :failed,
          metadata: (document.metadata || {}).merge("last_error" => error_info)
        )
      end
    end
  end
end
