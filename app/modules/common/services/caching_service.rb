module Common
  module Services
    class CachingService
      include Singleton

      # Cache TTL settings
      EMBEDDING_CACHE_TTL = 1.hour
      DOCUMENT_CHUNK_CACHE_TTL = 30.minutes
      SIMILARITY_CACHE_TTL = 15.minutes
      CHAT_CONTEXT_CACHE_TTL = 5.minutes

      def initialize
        @cache = Rails.cache
      end

      # Cache embeddings for frequently queried text
      def cache_embedding(text, embedding)
        return unless text.present? && embedding.present?

        cache_key = embedding_cache_key(text)
        @cache.write(cache_key, embedding, expires_in: EMBEDDING_CACHE_TTL)
      end

      def get_cached_embedding(text)
        return nil unless text.present?

        cache_key = embedding_cache_key(text)
        @cache.read(cache_key)
      end

      # Cache document chunks for faster retrieval
      def cache_document_chunks(document_id, chunks)
        return unless document_id.present? && chunks.present?

        cache_key = document_chunks_cache_key(document_id)
        @cache.write(cache_key, chunks, expires_in: DOCUMENT_CHUNK_CACHE_TTL)
      end

      def get_cached_document_chunks(document_id)
        return nil unless document_id.present?

        cache_key = document_chunks_cache_key(document_id)
        @cache.read(cache_key)
      end

      # Cache similarity search results
      def cache_similarity_results(query, collection_id, results)
        return unless query.present? && collection_id.present? && results.present?

        cache_key = similarity_cache_key(query, collection_id)

        # Store lightweight version with just IDs and scores
        cacheable_results = results.map do |chunk|
          {
            id: chunk.id,
            document_id: chunk.document_id,
            chunk_index: chunk.chunk_index,
            similarity_score: chunk.instance_variable_get(:@similarity_score)
          }
        end

        @cache.write(cache_key, cacheable_results, expires_in: SIMILARITY_CACHE_TTL)
      end

      def get_cached_similarity_results(query, collection_id)
        return nil unless query.present? && collection_id.present?

        cache_key = similarity_cache_key(query, collection_id)
        cached_results = @cache.read(cache_key)

        return nil unless cached_results.present?

        # Reconstruct objects from cached data
        embedding_ids = cached_results.map { |r| r[:id] }
        embeddings = Documents::Models::DocumentEmbedding.where(id: embedding_ids).includes(:document).index_by(&:id)

        cached_results.filter_map do |result|
          embedding = embeddings[result[:id]]
          if embedding
            embedding.instance_variable_set(:@similarity_score, result[:similarity_score])
            embedding
          end
        end
      end

      # Cache chat session context
      def cache_chat_context(session_id, context)
        return unless session_id.present? && context.present?

        cache_key = chat_context_cache_key(session_id)
        @cache.write(cache_key, context, expires_in: CHAT_CONTEXT_CACHE_TTL)
      end

      def get_cached_chat_context(session_id)
        return nil unless session_id.present?

        cache_key = chat_context_cache_key(session_id)
        @cache.read(cache_key)
      end

      # Cache document collection stats
      def cache_collection_stats(collection_id, stats)
        return unless collection_id.present? && stats.present?

        cache_key = collection_stats_cache_key(collection_id)
        @cache.write(cache_key, stats, expires_in: 1.hour)
      end

      def get_cached_collection_stats(collection_id)
        return nil unless collection_id.present?

        cache_key = collection_stats_cache_key(collection_id)
        @cache.read(cache_key)
      end

      # Invalidation methods
      def invalidate_document_caches(document_id)
        return unless document_id.present?

        @cache.delete(document_chunks_cache_key(document_id))

        # Invalidate collection stats if document belongs to a collection
        document = Documents::Models::Document.find_by(id: document_id)
        if document&.document_collection_id
          invalidate_collection_caches(document.document_collection_id)
        end
      end

      def invalidate_collection_caches(collection_id)
        return unless collection_id.present?

        @cache.delete(collection_stats_cache_key(collection_id))

        # Clear similarity search caches for this collection
        # Note: This is a simple approach; for production, consider using cache tags
        clear_similarity_caches_for_collection(collection_id)
      end

      def invalidate_chat_session_caches(session_id)
        return unless session_id.present?

        @cache.delete(chat_context_cache_key(session_id))
      end

      # Warm up caches proactively
      def warm_up_document_cache(document)
        return unless document.present?

        chunks = document.document_embeddings.ordered.includes(:document)
        cache_document_chunks(document.id, chunks) if chunks.any?
      end

      def warm_up_collection_cache(collection)
        return unless collection.present?

        stats = {
          document_count: collection.documents.count,
          total_embeddings: collection.documents.joins(:document_embeddings).count,
          processed_documents: collection.documents.where(status: :processed).count,
          last_updated: collection.updated_at
        }

        cache_collection_stats(collection.id, stats)
      end

      private

      def embedding_cache_key(text)
        # Use a hash to avoid key length issues and ensure uniqueness
        text_hash = Digest::SHA256.hexdigest(text.strip.downcase)
        "embedding:#{text_hash}"
      end

      def document_chunks_cache_key(document_id)
        "document_chunks:#{document_id}"
      end

      def similarity_cache_key(query, collection_id)
        query_hash = Digest::SHA256.hexdigest(query.strip.downcase)
        "similarity:#{collection_id}:#{query_hash}"
      end

      def chat_context_cache_key(session_id)
        "chat_context:#{session_id}"
      end

      def collection_stats_cache_key(collection_id)
        "collection_stats:#{collection_id}"
      end

      def clear_similarity_caches_for_collection(collection_id)
        # This is a simple implementation. For production, consider using Redis SCAN
        # or implementing proper cache tagging
        pattern = "similarity:#{collection_id}:*"

        if @cache.respond_to?(:delete_matched)
          @cache.delete_matched(pattern)
        else
          Rails.logger.warn "Cache doesn't support pattern deletion. Consider implementing proper cache invalidation."
        end
      end
    end
  end
end
