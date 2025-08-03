module Users
  module Models
    class Customer < ApplicationRecord
      # Associations
      has_many :users, class_name: Users::Models::User.name, dependent: :destroy
      has_many :document_collections, class_name: Documents::Models::DocumentCollection.name, dependent: :destroy
      has_many :subscriptions, class_name: 'Subscriptions::Models::Subscription', dependent: :destroy
      has_many :documents, through: :document_collections, class_name: 'Documents::Models::Document'

      # Validations
      validates :name, presence: true, length: { minimum: 2, maximum: 100 }
      validates :email, presence: true, uniqueness: true,
                format: { with: URI::MailTo::EMAIL_REGEXP }
      validates :domain, presence: true, uniqueness: true,
                format: { with: /\A[a-zA-Z0-9][a-zA-Z0-9-]{1,61}[a-zA-Z0-9]\.[a-zA-Z]{2,}\z/ }
      validates :status, presence: true, inclusion: { in: %w[active inactive pending] }

      # Enums
      enum :status, { pending: 0, active: 1, inactive: 2 }

      # Callbacks
      before_validation :normalize_email
      before_validation :extract_domain_from_email

      # Scopes
      scope :active, -> { where(status: :active) }
      scope :pending_approval, -> { where(status: :pending) }

      # Business logic methods
      def active_subscription
        subscriptions.active.first
      end

      def can_upload_documents?
        active_subscription&.allows_document_upload?
      end

      def document_upload_limit
        active_subscription&.document_upload_limit || 0
      end

      def current_document_count
        documents.count
      end

      def can_upload_more_documents?
        current_document_count < document_upload_limit
      end

      def admin_users
        users.admin
      end

      def regular_users
        users.regular
      end

      def read_only_users
        users.read_only
      end

      private

      def normalize_email
        self.email = email.downcase.strip if email.present?
      end

      def extract_domain_from_email
        return unless email.present?

        domain_part = email.split("@").last
        self.domain = domain_part if domain_part.present?
      end
    end
  end
end
