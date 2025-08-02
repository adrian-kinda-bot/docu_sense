class DocumentCollection < ApplicationRecord
  # Associations
  belongs_to :customer
  has_many :documents, dependent: :destroy
  has_many :chat_sessions, dependent: :destroy

  # Validations
  validates :name, presence: true, length: { minimum: 2, maximum: 100 }
  validates :description, length: { maximum: 500 }
  validates :category, presence: true, inclusion: { in: %w[hr legal policy technical other] }
  validates :status, presence: true, inclusion: { in: %w[active archived] }

  # Enums
  enum :category, { hr: 0, legal: 1, policy: 2, technical: 3, other: 4 }
  enum :status, { active: 0, archived: 1 }

  # Scopes
  scope :active, -> { where(status: :active) }
  scope :archived, -> { where(status: :archived) }
  scope :by_category, ->(category) { where(category: category) }

  # Business logic methods
  def document_count
    documents.count
  end

  def total_document_size
    documents.sum(:file_size)
  end

  def recent_documents(limit = 5)
    documents.order(created_at: :desc).limit(limit)
  end

  def can_add_documents?
    active? && customer.can_upload_more_documents?
  end

  def archive!
    update!(status: :archived)
  end

  def activate!
    update!(status: :active)
  end

  def has_embeddings?
    documents.any?(&:has_embeddings?)
  end

  def embedding_status
    if documents.empty?
      "no_documents"
    elsif documents.all?(&:has_embeddings?)
      "complete"
    elsif documents.any?(&:has_embeddings?)
      "partial"
    else
      "pending"
    end
  end

  def recent_chat_sessions(limit = 10)
    chat_sessions.order(updated_at: :desc).limit(limit)
  end

  def category_display_name
    category.humanize
  end

  def to_s
    name
  end
end
