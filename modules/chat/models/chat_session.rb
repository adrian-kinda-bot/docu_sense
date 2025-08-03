module Chat
  module Models
    class ChatSession < ApplicationRecord
      # Associations
      belongs_to :user, class_name: 'Users::Models::User'
      belongs_to :document_collection, class_name: 'Documents::Models::DocumentCollection'
      has_many :chat_messages, class_name: 'Chat::Models::ChatMessage', dependent: :destroy

      # Validations
      validates :title, presence: true, length: { minimum: 1, maximum: 200 }
      validates :status, presence: true, inclusion: { in: %w[active archived] }
      validates :document_collection, presence: true
      validate :document_collection_belongs_to_user_customer

      # Enums
      enum :status, { active: 0, archived: 1 }

      # Callbacks
      before_validation :set_default_title, on: :create

      # Scopes
      scope :active, -> { where(status: :active) }
      scope :archived, -> { where(status: :archived) }
      scope :recent, -> { order(updated_at: :desc) }

      # Business logic methods
      def message_count
        chat_messages.count
      end

      def user_message_count
        chat_messages.user_messages.count
      end

      def assistant_message_count
        chat_messages.assistant_messages.count
      end

      def last_message
        chat_messages.order(:created_at).last
      end

      def last_user_message
        chat_messages.user_messages.order(:created_at).last
      end

      def last_assistant_message
        chat_messages.assistant_messages.order(:created_at).last
      end

      def can_add_messages?
        active? && document_collection.active?
      end

      def archive!
        update!(status: :archived)
      end

      def activate!
        update!(status: :active)
      end

      def conversation_summary
        messages = chat_messages.order(:created_at).limit(10)
        messages.map { |msg| "#{msg.role}: #{msg.content[0..100]}..." }.join("\n")
      end

      def to_s
        title
      end

      private

      def document_collection_belongs_to_user_customer
        return unless document_collection.present? && user.present?

        unless user.customer.document_collections.include?(document_collection)
          errors.add(:document_collection, "must belong to your customer account")
        end
      end

      def set_default_title
        return if title.present?

        timestamp = created_at || Time.current
        if document_collection.present?
          self.title = "Chat about #{document_collection.name} - #{timestamp.strftime('%B %d, %Y')}"
        else
          self.title = "New Chat - #{timestamp.strftime('%B %d, %Y')}"
        end
      end
    end
  end
end
