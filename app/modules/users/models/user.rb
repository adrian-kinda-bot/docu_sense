module Users
  module Models
    class User < ApplicationRecord
      # Include default devise modules. Others available are:
      # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
      devise :database_authenticatable, :registerable,
            :recoverable, :rememberable, :validatable,
            :trackable, :confirmable

      # Associations
      belongs_to :customer, class_name: Users::Models::Customer.name
      has_many :chat_sessions, class_name: Chat::Models::ChatSession.name, dependent: :destroy
      has_many :chat_messages, through: :chat_sessions, class_name: Chat::Models::ChatMessage.name

      # Validations
      validates :first_name, presence: true, length: { minimum: 1, maximum: 50 }
      validates :last_name, presence: true, length: { maximum: 50 }
      validates :role, presence: true, inclusion: { in: %w[admin regular read_only] }
      validates :email, presence: true, uniqueness: true,
                format: { with: URI::MailTo::EMAIL_REGEXP }

      # Enums
      enum :role, { admin: 0, regular: 1, read_only: 2 }

      # Callbacks
      before_validation :normalize_email
      before_validation :validate_business_email

      # Scopes
      scope :active, -> { where(active: true) }
      scope :admin, -> { where(role: :admin) }
      scope :regular, -> { where(role: :regular) }
      scope :read_only, -> { where(role: :read_only) }

      # Business logic methods
      def full_name
        "#{first_name} #{last_name}".strip
      end

      def admin?
        role == "admin"
      end

      def regular?
        role == "regular"
      end

      def read_only?
        role == "read_only"
      end

      def can_upload_documents?
        return false unless active?
        return true if admin?
        regular?
      end

      def can_view_documents?
        active?
      end

      def can_chat_with_documents?
        return false unless active?
        return true if admin? || regular?
        false
      end

      def can_manage_users?
        admin?
      end

      def can_manage_subscriptions?
        admin?
      end

      def can_access_collection?(collection)
        return false unless active?
        return true if admin?
        collection.customer == customer
      end

      def recent_chat_sessions(limit = 10)
        chat_sessions.order(updated_at: :desc).limit(limit)
      end

      private

      def normalize_email
        self.email = email.downcase.strip if email.present?
      end

      def validate_business_email
        return unless email.present?

        # Ensure email domain matches customer domain
        email_domain = email.split("@").last
        unless email_domain == customer&.domain
          errors.add(:email, "must be from your company domain")
        end
      end
    end
  end
end
