module Documents
  module Models
    class DocumentEmbedding < ApplicationRecord
      # Associations
      belongs_to :document, class_name: Documents::Models::Document.name

      # Validations
      validates :content_chunk, presence: true
      validates :embedding_vector, presence: true
      validates :chunk_index, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
      validates :token_count, presence: true, numericality: { only_integer: true, greater_than: 0 }

      # Scopes
      scope :ordered, -> { order(:chunk_index) }
      scope :with_embeddings, -> { where.not(embedding_vector: nil) }
      scope :by_document_collection, ->(collection_id) {
        joins(document: :document_collection).where(document_collections: { id: collection_id })
      }

      # Callbacks
      before_save :normalize_embedding_vector
      after_save :update_document_stats

      # Business logic methods
      def similarity_with(query_embedding)
        return 0.0 unless embedding_vector.present? && query_embedding.present?

        vector1 = parsed_embedding_vector
        vector2 = ensure_array(query_embedding)

        return 0.0 unless vector1.present? && vector2.present? && vector1.length == vector2.length

        calculate_cosine_similarity(vector1, vector2)
      end

      def context_window(window_size: 1)
        # Return surrounding chunks for better context
        start_index = [ chunk_index - window_size, 0 ].max
        end_index = chunk_index + window_size

        document.document_embeddings
                .where(chunk_index: start_index..end_index)
                .ordered
                .pluck(:content_chunk)
                .join("\n\n")
      end

      def embedding_quality_score
        # Simple quality metric based on vector magnitude and content length
        return 0.0 unless embedding_vector.present? && content_chunk.present?

        vector = parsed_embedding_vector
        return 0.0 unless vector.present?

        magnitude = Math.sqrt(vector.sum { |x| x**2 })
        content_quality = [ content_chunk.length / 100.0, 10.0 ].min # Cap at 10

        (magnitude * content_quality).round(4)
      end

      def self.find_similar(query_embedding, limit: 10, threshold: 0.7)
        return none unless query_embedding.present?

        # This is a basic implementation. For better performance, consider using pgvector
        embeddings = with_embeddings.includes(:document)

        similarities = embeddings.map do |embedding|
          similarity = embedding.similarity_with(query_embedding)
          next if similarity < threshold

          [ embedding, similarity ]
        end.compact

        similarities.sort_by { |_, score| -score }
                   .first(limit)
                   .map(&:first)
      end

      def self.search_by_content(query, limit: 10)
        # Text-based search as fallback when embeddings aren't available
        where("content_chunk ILIKE ?", "%#{query}%")
          .includes(:document)
          .limit(limit)
      end

      def parsed_embedding_vector
        @parsed_embedding_vector ||= ensure_array(embedding_vector)
      end

      def to_s
        "Chunk #{chunk_index} of #{document.title}"
      end

      private

      def ensure_array(vector)
        case vector
        when Array
          vector
        when String
          begin
            JSON.parse(vector)
          rescue JSON::ParserError
            Rails.logger.error "Invalid embedding vector format for embedding #{id}"
            nil
          end
        else
          nil
        end
      end

      def calculate_cosine_similarity(vector1, vector2)
        dot_product = vector1.zip(vector2).sum { |a, b| a * b }
        magnitude1 = Math.sqrt(vector1.sum { |x| x**2 })
        magnitude2 = Math.sqrt(vector2.sum { |x| x**2 })

        return 0.0 if magnitude1.zero? || magnitude2.zero?

        dot_product / (magnitude1 * magnitude2)
      end

      def normalize_embedding_vector
        return unless embedding_vector.present?

        # Ensure embedding is stored as JSON string for database compatibility
        self.embedding_vector = embedding_vector.to_json unless embedding_vector.is_a?(String)
      end

      def update_document_stats
        return unless saved_change_to_embedding_vector?

        # Update document's embedding count and status
        document.update_column(:embeddings_count, document.document_embeddings.count) if document
      end
    end
  end
end
