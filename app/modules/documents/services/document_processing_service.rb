module Documents
  module Services
    class DocumentProcessingService
      include Singleton

      SUPPORTED_FORMATS = %w[txt pdf docx doc].freeze
      MAX_FILE_SIZE = 50.megabytes

      def process_document(document)
        return false unless document.file.attached?

        begin
          document.update!(status: :processing)

          # Extract text content
          content = extract_text_from_file(document)

          if content.present?
            document.update!(
              content: content,
              status: :processed,
              processed_at: Time.current
            )

            # Schedule embedding generation
            document.schedule_embedding_generation

            true
          else
            document.update!(status: :failed)
            false
          end
        rescue => e
          Rails.logger.error "Error processing document #{document.id}: #{e.message}"
          document.update!(status: :failed)
          false
        end
      end

      def validate_file(file)
        return { valid: false, error: "No file provided" } unless file.present?
        return { valid: false, error: "File too large (max #{MAX_FILE_SIZE / 1.megabyte}MB)" } if file.size > MAX_FILE_SIZE

        extension = file.filename.extension.downcase
        return { valid: false, error: "Unsupported file format. Supported: #{SUPPORTED_FORMATS.join(', ')}" } unless SUPPORTED_FORMATS.include?(extension)

        { valid: true }
      end

      def extract_text_from_file(document)
        case document.file_type
        when "txt"
          extract_txt_content(document.file)
        when "pdf"
          extract_pdf_content(document.file)
        when "docx"
          extract_docx_content(document.file)
        when "doc"
          extract_doc_content(document.file)
        else
          raise "Unsupported file type: #{document.file_type}"
        end
      end

      def sanitize_text(text)
        return "" if text.blank?

        # Remove excessive whitespace
        text = text.gsub(/\s+/, " ")

        # Remove non-printable characters
        text = text.gsub(/[^\p{Print}\p{Space}]/, "")

        # Basic HTML sanitization if needed
        text = Sanitize.fragment(text, elements: [])

        text.strip
      end

      private

      def extract_txt_content(file)
        content = file.download.force_encoding("UTF-8")
        sanitize_text(content)
      rescue => e
        Rails.logger.error "Error extracting text from TXT file: #{e.message}"
        nil
      end

      def extract_pdf_content(file)
        require "pdf-reader"

        content = []
        file.open do |f|
          reader = PDF::Reader.new(f)
          reader.pages.each do |page|
            content << page.text
          end
        end

        sanitize_text(content.join("\n"))
      rescue => e
        Rails.logger.error "Error extracting text from PDF file: #{e.message}"
        nil
      end

      def extract_docx_content(file)
        require "docx"

        file.open do |f|
          doc = Docx::Document.open(f.path)
          content = doc.paragraphs.map(&:text).join("\n")
          sanitize_text(content)
        end
      rescue => e
        Rails.logger.error "Error extracting text from DOCX file: #{e.message}"
        nil
      end

      def extract_doc_content(file)
        # For .doc files, we'll need a more sophisticated approach
        # This is a placeholder implementation
        "DOC file content extraction not yet implemented. Please convert to DOCX format."
      rescue => e
        Rails.logger.error "Error extracting text from DOC file: #{e.message}"
        nil
      end
    end
  end
end 