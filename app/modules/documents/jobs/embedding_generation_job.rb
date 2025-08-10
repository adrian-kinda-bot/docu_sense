module Documents
  module Jobs
    class EmbeddingGenerationJob < BaseSidekiqJob
      sidekiq_options queue: :default, retry: false

      def perform(document_id)
        document = Documents::Models::Document.find_by(id: document_id)
        return unless document&.can_generate_embeddings?

        begin
          # Split content into chunks
          chunks = split_content_into_chunks(document.content.squish)

          chunks.each_with_index do |chunk, index|
            # Generate embedding using OpenAI
            embedding = generate_embedding(chunk)

            # Store embedding
            document.document_embeddings.create!(
              content_chunk: chunk,
              embedding_vector: embedding,
              chunk_index: index,
              token_count: estimate_token_count(chunk),
              metadata: {
                chunk_size: chunk.length,
                chunk_index: index
              }
            )
          end

          Rails.logger.info "Generated #{chunks.length} embeddings for document #{document.id}"
        rescue => e
          Rails.logger.error "Embedding generation failed for document #{document_id}: #{e.message}"
          # Record error on document metadata
          new_metadata = (document.metadata || {}).dup
          document.update!(
            metadata: new_metadata.merge(
              "last_error" => {
                "step" => "embedding_generation",
                "message" => e.message,
                "error_class" => e.class.name,
                "occurred_at" => Time.current.iso8601
              }
            ),
            status: :failed
          ) if document
        end
      end

      private

      def split_content_into_chunks(content, max_chunk_size = 8000)
        sentences = content.scan(/[^.!?]+[.!?]*/).map(&:strip).reject(&:empty?)

        chunks = []
        buffer = []

        sentences.each do |sentence|
          if buffer.join(" ").length + sentence.length > max_chunk_size && buffer.any?
            chunks << buffer.join(" ")
            buffer.clear
          end
          buffer << sentence
        end

        chunks << buffer.join(" ") if buffer.any?
        chunks
      end

      def generate_embedding(text)
        Openai::Services::GenerateEmbeddingsService.new(text).call
      end

      def estimate_token_count(text)
        # Rough estimation: 1 token ≈ 4 characters
        (text.length / 4.0).ceil
      end
    end
  end
end
