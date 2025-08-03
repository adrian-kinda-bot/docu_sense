module Subscriptions
  module Models
    class Subscription < ApplicationRecord
      # Associations
      belongs_to :customer, class_name: Users::Models::Customer.name

      # Validations
      validates :plan_type, presence: true, inclusion: { in: %w[starter professional enterprise] }
      validates :status, presence: true, inclusion: { in: %w[active inactive cancelled pending] }
      validates :start_date, presence: true
      validates :end_date, presence: true
      validates :monthly_price, presence: true, numericality: { greater_than_or_equal_to: 0 }

      # Enums
      enum :plan_type, { starter: 0, professional: 1, enterprise: 2 }
      enum :status, { pending: 0, active: 1, inactive: 2, cancelled: 3 }

      # Callbacks
      before_validation :set_default_dates, on: :create
      before_validation :set_plan_limits, on: :create

      # Scopes
      scope :active, -> { where(status: :active) }
      scope :expired, -> { where("end_date < ?", Date.current) }
      scope :expiring_soon, -> { where(end_date: Date.current..30.days.from_now) }

      # Business logic methods
      def active?
        status == "active" && !expired?
      end

      def expired?
        end_date < Date.current
      end

      def days_until_expiry
        (end_date - Date.current).to_i
      end

      def allows_document_upload?
        active? && customer.current_document_count < document_upload_limit
      end

      def document_upload_limit
        case plan_type
        when "starter"
          50
        when "professional"
          200
        when "enterprise"
          1000
        else
          0
        end
      end

      def chat_message_limit
        case plan_type
        when "starter"
          1000
        when "professional"
          5000
        when "enterprise"
          Float::INFINITY
        else
          0
        end
      end

      def user_limit
        case plan_type
        when "starter"
          5
        when "professional"
          25
        when "enterprise"
          100
        else
          0
        end
      end

      def storage_limit_gb
        case plan_type
        when "starter"
          5
        when "professional"
          20
        when "enterprise"
          100
        else
          0
        end
      end

      def plan_features
        case plan_type
        when "starter"
          {
            document_upload_limit: 50,
            chat_message_limit: 1000,
            user_limit: 5,
            storage_limit_gb: 5,
            features: [ "Document Upload", "AI Chat", "Basic Analytics" ]
          }
        when "professional"
          {
            document_upload_limit: 200,
            chat_message_limit: 5000,
            user_limit: 25,
            storage_limit_gb: 20,
            features: [ "Document Upload", "AI Chat", "Advanced Analytics", "Priority Support", "Custom Categories" ]
          }
        when "enterprise"
          {
            document_upload_limit: 1000,
            chat_message_limit: Float::INFINITY,
            user_limit: 100,
            storage_limit_gb: 100,
            features: [ "Document Upload", "AI Chat", "Advanced Analytics", "Priority Support", "Custom Categories", "API Access", "SSO Integration", "Dedicated Support" ]
          }
        end
      end

      def monthly_price_display
        "$#{monthly_price}/month"
      end

      def activate!
        update!(status: :active, start_date: Date.current)
      end

      def cancel!
        update!(status: :cancelled, end_date: Date.current)
      end

      def renew!
        update!(end_date: end_date + 1.month)
      end

      private

      def set_default_dates
        self.start_date ||= Date.current
        self.end_date ||= start_date + 1.month
      end

      def set_plan_limits
        return unless plan_type.present?

        case plan_type
        when "starter"
          self.monthly_price = 29
        when "professional"
          self.monthly_price = 99
        when "enterprise"
          self.monthly_price = 299
        end
      end
    end
  end
end
