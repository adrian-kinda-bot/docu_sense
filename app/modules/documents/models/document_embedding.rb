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

      # Business logic methods
      def similarity_with(query_embedding)
        return 0.0 unless embedding_vector.present? && query_embedding.present?

        # Calculate cosine similarity between vectors
        vector1 = embedding_vector
        vector2 = query_embedding

        dot_product = vector1.zip(vector2).sum { |a, b| a * b }
        magnitude1 = Math.sqrt(vector1.sum { |x| x**2 })
        magnitude2 = Math.sqrt(vector2.sum { |x| x**2 })

        return 0.0 if magnitude1.zero? || magnitude2.zero?

        dot_product / (magnitude1 * magnitude2)
      end

      def context_window
        # Return surrounding chunks for better context
        document.document_embeddings
                .where(chunk_index: (chunk_index - 1)..(chunk_index + 1))
                .ordered
                .pluck(:content_chunk)
                .join("\n")
      end

      def to_s
        "Chunk #{chunk_index} of #{document.title}"
      end
    end
  end
end
