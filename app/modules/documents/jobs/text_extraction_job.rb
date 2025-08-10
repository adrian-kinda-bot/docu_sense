module Documents
  module Jobs
    class TextExtractionJob < BaseSidekiqJob
      sidekiq_options queue: :default, retry: true

      def perform(document_id)
        document = Documents::Models::Document.find_by(id: document_id)
        return unless document

        document.update!(status: :processing)

        begin
          content = document.extract_text_content

          if content.present?
            document.update!(
              content: content,
              status: :processed,
              processed_at: Time.current
            )

            # Schedule embedding generation
            document.schedule_embedding_generation
          else
            new_metadata = (document.metadata || {}).dup
            document.update!(
              status: :failed,
              metadata: new_metadata.merge(
                "last_error" => {
                  "step" => "text_extraction",
                  "message" => "No content extracted",
                  "occurred_at" => Time.current.iso8601
                }
              )
            )
          end
        rescue => e
          Rails.logger.error "Text extraction failed for document #{document_id}: #{e.message}"
          if document
            new_metadata = (document.metadata || {}).dup
            document.update!(
              status: :failed,
              metadata: new_metadata.merge(
                "last_error" => {
                  "step" => "text_extraction",
                  "message" => e.message,
                  "error_class" => e.class.name,
                  "occurred_at" => Time.current.iso8601
                }
              )
            )
          end
        end
      end
    end
  end
end
