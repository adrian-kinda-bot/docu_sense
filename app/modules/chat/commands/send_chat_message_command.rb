module Chat
  module Commands
    class SendChatMessageCommand
      include ActiveModel::Model

      attr_accessor :content, :chat_session_id, :user_id

      validates :content, presence: true, length: { minimum: 1, maximum: 4000 }
      validates :chat_session_id, presence: true
      validates :user_id, presence: true

      def execute
        return false unless valid?

        chat_session = Chat::ChatSession.find(chat_session_id)
        user = Users::User.find(user_id)

        # Validate user can access chat session
        return false unless chat_session.user == user

        # Validate chat session is active
        return false unless chat_session.can_add_messages?

        # Create chat message
        chat_message = chat_session.chat_messages.build(
          content: content,
          role: "user",
          message_type: "question",
          user: user
        )

        if chat_message.save
          # Publish event
          Chat::Events::ChatMessageSentEvent.new(chat_message: chat_message, user: user).publish

          # Schedule AI processing
          Chat::Jobs::ProcessChatMessageJob.perform_async(chat_message.id)

          true
        else
          errors.merge!(chat_message.errors)
          false
        end
      end
    end
  end
end
