module Chat
  module Services
    class DocumentRetrievalService
      include Singleton

      SIMILARITY_THRESHOLD = 0.7
      MAX_RELEVANT_CHUNKS = 8
      MAX_CONTEXT_TOKENS = 3000

      def initialize
        @openai_client = Openai::Services::ClientService.instance
        @cache_service = Common::Services::CachingService.instance
      end

      # Find the most relevant document chunks for a query
      def find_relevant_chunks(query, document_collection, limit: MAX_RELEVANT_CHUNKS)
        return [] unless query.present? && document_collection.present?

        # Generate query embedding
        query_embedding = @openai_client.generate_embeddings(query)
        return [] unless query_embedding.present?

        # Get all embeddings from the document collection
        embeddings = Documents::Models::DocumentEmbedding.joins(
          document: :document_collection
        ).where(
          document_collections: { id: document_collection.id }
        ).where.not(embedding_vector: nil).includes(:document)

        return [] if embeddings.empty?

        # Calculate similarities and rank results
        ranked_chunks = calculate_similarities(embeddings, query_embedding).select do |_, similarity|
          similarity >= SIMILARITY_THRESHOLD
        end.sort_by { |_, similarity| -similarity }.first(limit).map(&:first)

        # Optimize context by considering token limits and diversity
        optimize_context_selection(ranked_chunks, query)
      end

      # Build contextual prompt from relevant chunks
      def build_context_from_chunks(chunks)
        return "" if chunks.empty?

        context_parts = chunks.map.with_index do |chunk, index|
          document_title = chunk.document.title
          chunk_text = chunk.content_chunk

          <<~CHUNK
            [Document: #{document_title}]
            #{chunk_text}
          CHUNK
        end

        context_parts.join("\n\n---\n\n")
      end

      # Enhanced search with reranking for better results
      def search_with_reranking(query, document_collection, limit: MAX_RELEVANT_CHUNKS)
        # First pass: Get initial relevant chunks
        initial_chunks = find_relevant_chunks(query, document_collection, limit: limit * 2)
        return initial_chunks if initial_chunks.length <= limit

        # Second pass: Rerank based on query-specific criteria
        rerank_chunks(initial_chunks, query, limit)
      end

      private

      def calculate_similarities(embeddings, query_embedding)
        embeddings.map do |embedding|
          similarity = calculate_cosine_similarity(
            embedding.embedding_vector,
            query_embedding
          )
          [ embedding, similarity ]
        end
      end

      def calculate_cosine_similarity(vector1, vector2)
        return 0.0 unless vector1.present? && vector2.present?

        # Ensure vectors are arrays of numbers
        v1 = vector1.is_a?(String) ? JSON.parse(vector1) : vector1
        v2 = vector2.is_a?(String) ? JSON.parse(vector2) : vector2

        return 0.0 unless v1.length == v2.length

        dot_product = v1.zip(v2).sum { |a, b| a * b }
        magnitude1 = Math.sqrt(v1.sum { |x| x**2 })
        magnitude2 = Math.sqrt(v2.sum { |x| x**2 })

        return 0.0 if magnitude1.zero? || magnitude2.zero?

        dot_product / (magnitude1 * magnitude2)
      end

      def optimize_context_selection(chunks, query)
        return chunks if chunks.empty?

        # Ensure we don't exceed token limits
        optimized_chunks = []
        total_tokens = 0

        # Sort by similarity score first, then optimize for diversity
        chunks.each do |chunk|
          chunk_tokens = chunk.token_count || @openai_client.estimate_token_count(chunk.content_chunk)

          if total_tokens + chunk_tokens <= MAX_CONTEXT_TOKENS
            optimized_chunks << chunk
            total_tokens += chunk_tokens
          else
            break
          end
        end

        # Ensure diversity across documents if possible
        ensure_document_diversity(optimized_chunks)
      end

      def ensure_document_diversity(chunks)
        return chunks if chunks.length <= 3

        # Group by document
        chunks_by_document = chunks.group_by { |chunk| chunk.document_id }

        # If all chunks are from the same document, keep them all
        return chunks if chunks_by_document.keys.length == 1

        # Balance chunks across documents
        balanced_chunks = []
        document_chunks = chunks_by_document.values.sort_by(&:length).reverse

        # Take chunks round-robin style from different documents
        max_iterations = chunks.length
        iteration = 0

        while balanced_chunks.length < chunks.length && iteration < max_iterations
          document_chunks.each do |doc_chunks|
            if doc_chunks.any? && balanced_chunks.length < chunks.length
              balanced_chunks << doc_chunks.shift
            end
          end
          iteration += 1
        end

        balanced_chunks.compact
      end

      def rerank_chunks(chunks, query, limit)
        # Simple reranking based on exact keyword matches and context relevance
        query_words = extract_keywords(query.downcase)

        scored_chunks = chunks.map do |chunk|
          content_lower = chunk.content_chunk.downcase

          # Calculate keyword match score
          keyword_score = query_words.sum do |word|
            content_lower.scan(word).length * (word.length > 3 ? 2 : 1)
          end

          # Boost score for chunks with surrounding context
          context_score = chunk.chunk_index > 0 ? 0.1 : 0

          total_score = keyword_score + context_score
          [ chunk, total_score ]
        end

        # Sort by combined score and return top results
        scored_chunks.sort_by { |_, score| -score }
                     .first(limit)
                     .map(&:first)
      end

      def extract_keywords(text)
        # Simple keyword extraction (you could use more sophisticated NLP here)
        words = text.split(/\W+/).reject(&:empty?)

        # Filter out common stop words
        stop_words = %w[the a an and or but in on at to for of with by from up about into over after]
        keywords = words.reject { |word| stop_words.include?(word) || word.length < 3 }

        # Return unique keywords
        keywords.uniq
      end
    end
  end
end
