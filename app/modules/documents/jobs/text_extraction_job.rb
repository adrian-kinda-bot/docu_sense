module Documents
  module Jobs
    class TextExtractionJob < ApplicationJob
      queue_as :default

      def perform(document)
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
          Rails.logger.error "Text extraction failed for document #{document.id}: #{e.message}"
          document.update!(status: :failed)
        end
      end
    end
  end
end 