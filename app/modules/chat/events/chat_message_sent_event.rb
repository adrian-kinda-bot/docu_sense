module Chat
  module Events
    class ChatMessageSentEvent
      attr_reader :chat_message, :user, :occurred_at

      def initialize(chat_message:, user:, occurred_at: Time.current)
        @chat_message = chat_message
        @user = user
        @occurred_at = occurred_at
      end

      def publish
        # Log the event
        Rails.logger.info "Chat message sent: #{chat_message.content[0..50]}... by user #{user.id}"

        # You could integrate with an event bus here
        # EventBus.publish(self)

        # Trigger any immediate side effects
        update_chat_session_activity
        track_message_metrics
      end

      private

      def update_chat_session_activity
        chat_message.chat_session.touch(:last_activity_at)
      end

      def track_message_metrics
        # Track message count for analytics
        Rails.logger.info "Message count for session #{chat_message.chat_session_id}: #{chat_message.chat_session.message_count}"
      end
    end
  end
end 