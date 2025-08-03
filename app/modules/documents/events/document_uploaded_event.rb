module Documents
  module Events
    class DocumentUploadedEvent
      attr_reader :document, :user, :occurred_at

      def initialize(document:, user:, occurred_at: Time.current)
        @document = document
        @user = user
        @occurred_at = occurred_at
      end

      def publish
        # Log the event
        Rails.logger.info "Document uploaded: #{document.title} by user #{user.id}"

        # You could integrate with an event bus here
        # EventBus.publish(self)

        # Trigger any immediate side effects
        notify_admin_if_large_file
      end

      private

      def notify_admin_if_large_file
        return unless document.file_size > 10.megabytes

        # Notify admins about large file upload
        Rails.logger.info "Large file uploaded: #{document.title} (#{document.file_size / 1.megabyte}MB)"
      end
    end
  end
end 