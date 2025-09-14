module Analytics
  module Services
    class MonitoringService
      include Singleton

      def initialize
        @cache_service = Common::Services::CachingService.instance
      end

      # Track embedding generation metrics
      def track_embedding_generation(document_id, chunks_created:, total_tokens:, processing_time:, model_used:)
        metrics = {
          document_id: document_id,
          chunks_created: chunks_created,
          total_tokens: total_tokens,
          processing_time_seconds: processing_time,
          model_used: model_used,
          tokens_per_second: total_tokens / [ processing_time, 1 ].max,
          timestamp: Time.current
        }

        log_metrics("embedding_generation", metrics)
        update_embedding_stats(metrics)
      end

      # Track chat interaction metrics
      def track_chat_interaction(chat_message_id, relevant_chunks_found:, response_time:, context_tokens:, total_tokens:, cost:)
        metrics = {
          chat_message_id: chat_message_id,
          relevant_chunks_found: relevant_chunks_found,
          response_time_seconds: response_time,
          context_tokens: context_tokens,
          total_tokens: total_tokens,
          cost: cost,
          timestamp: Time.current
        }

        log_metrics("chat_interaction", metrics)
        update_chat_stats(metrics)
      end

      # Track similarity search performance
      def track_similarity_search(query, collection_id, chunks_found:, search_time:, cache_hit:)
        metrics = {
          query_length: query.length,
          collection_id: collection_id,
          chunks_found: chunks_found,
          search_time_seconds: search_time,
          cache_hit: cache_hit,
          timestamp: Time.current
        }

        log_metrics("similarity_search", metrics)
        update_search_stats(metrics)
      end

      # Track document processing metrics
      def track_document_processing(document_id, file_size:, processing_time:, chunks_created:, success:)
        metrics = {
          document_id: document_id,
          file_size_bytes: file_size,
          processing_time_seconds: processing_time,
          chunks_created: chunks_created,
          success: success,
          processing_rate: file_size / [ processing_time, 1 ].max,
          timestamp: Time.current
        }

        log_metrics("document_processing", metrics)
        update_processing_stats(metrics)
      end

      # Get embedding quality metrics
      def get_embedding_quality_metrics(time_range: 24.hours)
        {
          total_embeddings_generated: get_total_embeddings_in_range(time_range),
          average_processing_time: get_average_processing_time(time_range),
          average_chunks_per_document: get_average_chunks_per_document(time_range),
          token_usage_stats: get_token_usage_stats(time_range),
          success_rate: get_embedding_success_rate(time_range)
        }
      end

      # Get chat effectiveness metrics
      def get_chat_effectiveness_metrics(time_range: 24.hours)
        {
          total_interactions: get_total_chat_interactions(time_range),
          average_response_time: get_average_chat_response_time(time_range),
          average_relevant_chunks: get_average_relevant_chunks(time_range),
          total_cost: get_total_chat_cost(time_range),
          cache_hit_rate: get_cache_hit_rate(time_range)
        }
      end

      # Get system performance metrics
      def get_system_performance_metrics
        {
          active_documents: get_active_document_count,
          total_embeddings: get_total_embedding_count,
          cache_stats: get_cache_performance_stats,
          error_rates: get_error_rate_stats,
          resource_usage: get_resource_usage_stats
        }
      end

      # Generate alerts for issues
      def check_for_alerts
        alerts = []

        # Check embedding generation rate
        recent_embedding_failures = get_embedding_failure_rate(1.hour)
        if recent_embedding_failures > 0.1 # 10% failure rate
          alerts << {
            type: "high_embedding_failure_rate",
            severity: "warning",
            message: "Embedding generation failure rate is #{(recent_embedding_failures * 100).round(1)}%",
            timestamp: Time.current
          }
        end

        # Check chat response times
        avg_response_time = get_average_chat_response_time(1.hour)
        if avg_response_time > 10 # 10 seconds
          alerts << {
            type: "slow_chat_responses",
            severity: "warning",
            message: "Average chat response time is #{avg_response_time.round(1)} seconds",
            timestamp: Time.current
          }
        end

        # Check OpenAI API costs
        hourly_cost = get_total_chat_cost(1.hour)
        if hourly_cost > 10 # $10 per hour threshold
          alerts << {
            type: "high_api_costs",
            severity: "critical",
            message: "OpenAI API costs are $#{hourly_cost.round(2)} in the last hour",
            timestamp: Time.current
          }
        end

        alerts
      end

      private

      def log_metrics(event_type, metrics)
        Rails.logger.info "[METRICS:#{event_type.upcase}] #{metrics.to_json}"
      end

      def update_embedding_stats(metrics)
        stats_key = "embedding_stats:#{Date.current}"
        existing_stats = Rails.cache.read(stats_key) || default_embedding_stats

        existing_stats[:total_documents] += 1
        existing_stats[:total_chunks] += metrics[:chunks_created]
        existing_stats[:total_tokens] += metrics[:total_tokens]
        existing_stats[:total_processing_time] += metrics[:processing_time_seconds]
        existing_stats[:last_updated] = Time.current

        Rails.cache.write(stats_key, existing_stats, expires_in: 2.days)
      end

      def update_chat_stats(metrics)
        stats_key = "chat_stats:#{Date.current}"
        existing_stats = Rails.cache.read(stats_key) || default_chat_stats

        existing_stats[:total_interactions] += 1
        existing_stats[:total_response_time] += metrics[:response_time_seconds]
        existing_stats[:total_chunks_found] += metrics[:relevant_chunks_found]
        existing_stats[:total_cost] += metrics[:cost] || 0
        existing_stats[:last_updated] = Time.current

        Rails.cache.write(stats_key, existing_stats, expires_in: 2.days)
      end

      def update_search_stats(metrics)
        stats_key = "search_stats:#{Date.current}"
        existing_stats = Rails.cache.read(stats_key) || default_search_stats

        existing_stats[:total_searches] += 1
        existing_stats[:total_search_time] += metrics[:search_time_seconds]
        existing_stats[:cache_hits] += 1 if metrics[:cache_hit]
        existing_stats[:last_updated] = Time.current

        Rails.cache.write(stats_key, existing_stats, expires_in: 2.days)
      end

      def update_processing_stats(metrics)
        stats_key = "processing_stats:#{Date.current}"
        existing_stats = Rails.cache.read(stats_key) || default_processing_stats

        existing_stats[:total_processed] += 1
        existing_stats[:total_processing_time] += metrics[:processing_time_seconds]
        existing_stats[:total_file_size] += metrics[:file_size_bytes]
        existing_stats[:successful_processing] += 1 if metrics[:success]
        existing_stats[:last_updated] = Time.current

        Rails.cache.write(stats_key, existing_stats, expires_in: 2.days)
      end

      def default_embedding_stats
        {
          total_documents: 0,
          total_chunks: 0,
          total_tokens: 0,
          total_processing_time: 0,
          last_updated: Time.current
        }
      end

      def default_chat_stats
        {
          total_interactions: 0,
          total_response_time: 0,
          total_chunks_found: 0,
          total_cost: 0,
          last_updated: Time.current
        }
      end

      def default_search_stats
        {
          total_searches: 0,
          total_search_time: 0,
          cache_hits: 0,
          last_updated: Time.current
        }
      end

      def default_processing_stats
        {
          total_processed: 0,
          total_processing_time: 0,
          total_file_size: 0,
          successful_processing: 0,
          last_updated: Time.current
        }
      end

      # Helper methods for metric calculations
      def get_total_embeddings_in_range(time_range)
        Documents::Models::DocumentEmbedding.where(created_at: time_range.ago..Time.current).count
      end

      def get_average_processing_time(time_range)
        # This would need actual timing data stored somewhere
        stats_key = "embedding_stats:#{Date.current}"
        stats = Rails.cache.read(stats_key) || default_embedding_stats
        return 0 if stats[:total_documents] == 0

        stats[:total_processing_time] / stats[:total_documents]
      end

      def get_average_chunks_per_document(time_range)
        stats_key = "embedding_stats:#{Date.current}"
        stats = Rails.cache.read(stats_key) || default_embedding_stats
        return 0 if stats[:total_documents] == 0

        stats[:total_chunks] / stats[:total_documents]
      end

      def get_token_usage_stats(time_range)
        stats_key = "embedding_stats:#{Date.current}"
        stats = Rails.cache.read(stats_key) || default_embedding_stats

        {
          total_tokens: stats[:total_tokens],
          average_tokens_per_chunk: stats[:total_chunks] > 0 ? stats[:total_tokens] / stats[:total_chunks] : 0
        }
      end

      def get_embedding_success_rate(time_range)
        # This would need failure tracking
        0.95 # Placeholder - implement based on actual error logging
      end

      def get_total_chat_interactions(time_range)
        Chat::Models::ChatMessage.where(role: :user, created_at: time_range.ago..Time.current).count
      end

      def get_average_chat_response_time(time_range)
        stats_key = "chat_stats:#{Date.current}"
        stats = Rails.cache.read(stats_key) || default_chat_stats
        return 0 if stats[:total_interactions] == 0

        stats[:total_response_time] / stats[:total_interactions]
      end

      def get_average_relevant_chunks(time_range)
        stats_key = "chat_stats:#{Date.current}"
        stats = Rails.cache.read(stats_key) || default_chat_stats
        return 0 if stats[:total_interactions] == 0

        stats[:total_chunks_found] / stats[:total_interactions]
      end

      def get_total_chat_cost(time_range)
        stats_key = "chat_stats:#{Date.current}"
        stats = Rails.cache.read(stats_key) || default_chat_stats
        stats[:total_cost]
      end

      def get_cache_hit_rate(time_range)
        stats_key = "search_stats:#{Date.current}"
        stats = Rails.cache.read(stats_key) || default_search_stats
        return 0 if stats[:total_searches] == 0

        stats[:cache_hits].to_f / stats[:total_searches]
      end

      def get_active_document_count
        Documents::Models::Document.where(status: :processed).count
      end

      def get_total_embedding_count
        Documents::Models::DocumentEmbedding.count
      end

      def get_cache_performance_stats
        # This would depend on your cache implementation
        {
          cache_size: "unknown",
          hit_rate: get_cache_hit_rate(24.hours),
          memory_usage: "unknown"
        }
      end

      def get_error_rate_stats
        # This would need proper error tracking
        {
          embedding_errors: 0.05,
          chat_errors: 0.02,
          api_errors: 0.01
        }
      end

      def get_resource_usage_stats
        # This would need system monitoring
        {
          cpu_usage: "unknown",
          memory_usage: "unknown",
          disk_usage: "unknown"
        }
      end

      def get_embedding_failure_rate(time_range)
        # This would need actual failure tracking
        0.05 # Placeholder
      end
    end
  end
end
