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
            document.update!(status: :failed)
          end
        rescue => e
          Rails.logger.error "Text extraction failed for document #{document_id}: #{e.message}"
          document.update!(status: :failed) if document
        end
      end
    end
  end
end
