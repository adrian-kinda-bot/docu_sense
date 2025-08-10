module Documents
  module Models
    class Document < ApplicationRecord
      # Associations
      belongs_to :document_collection, class_name: Documents::Models::DocumentCollection.name
      has_one :customer, through: :document_collection, class_name: Users::Models::Customer.name
      has_many :document_embeddings, class_name: Documents::Models::DocumentEmbedding.name, dependent: :destroy
      has_one_attached :file

      # Validations
      validates :title, presence: true, length: { minimum: 1, maximum: 200 }
      validates :file_type, presence: true, inclusion: { in: %w[txt pdf docx doc] }
      validates :file_size, presence: true, numericality: { greater_than: 0 }
      validates :status, presence: true, inclusion: { in: %w[uploaded processing processed failed] }

      # Enums
      enum :file_type, { txt: 0, pdf: 1, docx: 2, doc: 3 }
      enum :status, { uploaded: 0, processing: 1, processed: 2, failed: 3 }

      # Callbacks
      before_validation :set_file_attributes, on: :create
      after_create :schedule_text_extraction

      # Scopes
      scope :processed, -> { where(status: :processed) }
      scope :with_embeddings, -> { joins(:document_embeddings) }
      scope :recent, -> { order(created_at: :desc) }

      # Business logic methods
      def file_extension
        file.filename.extension.downcase
      end

      def file_name
        file.filename.to_s
      end

      def has_embeddings?
        document_embeddings.exists?
      end

      def embedding_count
        document_embeddings.count
      end

      def can_generate_embeddings?
        content.present? && !has_embeddings?
      end

      def schedule_embedding_generation
        return unless can_generate_embeddings?

        Documents::Jobs::GenerateDocumentEmbeddingJob.perform_async(id)
      end

      def extract_text_content
        case file_type
        when "txt"
          extract_txt_content
        when "pdf"
          extract_pdf_content
        when "docx"
          extract_docx_content
        when "doc"
          extract_doc_content
        else
          raise "Unsupported file type: #{file_type}"
        end
      end

      def processing_failed?
        status == "failed"
      end

      def ready_for_chat?
        processed? && has_embeddings?
      end

      def to_s
        title
      end

      private

      def set_file_attributes
        return unless file.attached?

        self.title ||= file.filename.base
        self.file_type = file_extension
        self.file_size = file.byte_size
      end

      def schedule_text_extraction
        Documents::Jobs::TextExtractionJob.perform_async(id)
      end

      def extract_txt_content
        file.download.force_encoding("UTF-8")
      rescue => e
        Rails.logger.error "Error extracting text from TXT file: #{e.message}"
        nil
      end

      def extract_pdf_content
        require "pdf-reader"

        content = []
        file.open do |f|
          reader = PDF::Reader.new(f)
          reader.pages.each do |page|
            content << page.text
          end
        end
        content.join("\n")
      rescue => e
        Rails.logger.error "Error extracting text from PDF file: #{e.message}"
        nil
      end

      def extract_docx_content
        require "docx"

        file.open do |f|
          doc = Docx::Document.open(f.path)
          doc.paragraphs.map(&:text).join("\n")
        end
      rescue => e
        Rails.logger.error "Error extracting text from DOCX file: #{e.message}"
        nil
      end

      def extract_doc_content
        require "roo"

        file.open do |f|
          # For .doc files, we'll need to convert them or use a different approach
          # For now, we'll return a placeholder
          "DOC file content extraction not yet implemented"
        end
      rescue => e
        Rails.logger.error "Error extracting text from DOC file: #{e.message}"
        nil
      end
    end
  end
end
