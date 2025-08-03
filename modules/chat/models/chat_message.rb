module Chat
  module Models
    class ChatMessage < ApplicationRecord
      # Associations
      belongs_to :chat_session, class_name: Chat::Models::ChatSession.name
      belongs_to :user, class_name: 'Users::Models::User'

      # Validations
      validates :content, presence: true, length: { minimum: 1, maximum: 4000 }
      validates :role, presence: true, inclusion: { in: %w[user assistant] }
      validates :message_type, presence: true, inclusion: { in: %w[text question answer] }

      # Enums
      enum :role, { user: 0, assistant: 1 }
      enum :message_type, { text: 0, question: 1, answer: 2 }

      # Scopes
      scope :user_messages, -> { where(role: :user) }
      scope :assistant_messages, -> { where(role: :assistant) }
      scope :questions, -> { where(message_type: :question) }
      scope :answers, -> { where(message_type: :answer) }
      scope :ordered, -> { order(:created_at) }

      # Business logic methods
      def is_user_message?
        role == "user"
      end

      def is_assistant_message?
        role == "assistant"
      end

      def is_question?
        message_type == "question"
      end

      def is_answer?
        message_type == "answer"
      end

      def truncated_content(length = 100)
        content.length > length ? "#{content[0...length]}..." : content
      end

      def word_count
        content.split(/\s+/).count
      end

      def character_count
        content.length
      end

      def to_s
        "#{role.humanize}: #{truncated_content}"
      end
    end
  end
end
