# DocuSense Application Configuration
# This file centralizes all configuration for the document scanning and AI chatbot system

module DocusenseConfig
  # OpenAI Configuration
  OPENAI_CONFIG = {
    # Models
    embedding_model: "text-embedding-3-small",
    chat_model: "gpt-4o-mini", # More cost-effective than gpt-4-turbo
    title_generation_model: "gpt-3.5-turbo",

    # API Settings
    max_retries: 3,
    request_timeout: 30,
    initial_retry_delay: 1,

    # Token Limits
    max_embedding_tokens: 8000,
    max_chat_tokens: 4000,
    max_context_tokens: 3000,

    # Cost Optimization
    temperature: 0.7,
    max_completion_tokens: 1500,

    # Rate Limiting
    requests_per_minute: 50,
    rate_limit_delay: 0.1
  }

  # Document Processing Configuration
  DOCUMENT_CONFIG = {
    # Supported file types
    supported_formats: %w[txt pdf docx doc],
    max_file_size: 50.megabytes,

    # Text Processing
    min_chunk_size: 100,
    default_chunk_size: 1000,
    chunk_overlap: 200,

    # Quality Control
    min_content_length: 50,
    max_content_length: 10.megabytes,

    # Processing Options
    sanitize_html: true,
    normalize_whitespace: true,
    extract_metadata: true
  }.freeze

  # Chat and RAG Configuration
  CHAT_CONFIG = {
    # Retrieval Settings
    similarity_threshold: 0.7,
    max_relevant_chunks: 8,
    context_window_size: 1,

    # Response Generation
    max_conversation_history: 6, # Last 3 exchanges
    include_source_citations: true,
    response_temperature: 0.7,

    # Performance
    enable_reranking: true,
    enable_context_optimization: true,
    enable_document_diversity: true
  }.freeze

  # Caching Configuration
  CACHE_CONFIG = {
    # TTL Settings (in seconds)
    embedding_ttl: 1.hour,
    document_chunks_ttl: 30.minutes,
    similarity_results_ttl: 15.minutes,
    chat_context_ttl: 5.minutes,
    collection_stats_ttl: 1.hour,

    # Cache Keys
    embedding_prefix: "embedding",
    chunks_prefix: "document_chunks",
    similarity_prefix: "similarity",
    context_prefix: "chat_context",
    stats_prefix: "collection_stats",

    # Performance
    cache_warming_enabled: true,
    async_cache_updates: true
  }

  # Monitoring and Analytics Configuration
  MONITORING_CONFIG = {
    # Metrics Collection
    track_embedding_generation: true,
    track_chat_interactions: true,
    track_similarity_searches: true,
    track_document_processing: true,

    # Alert Thresholds
    max_embedding_failure_rate: 0.10, # 10%
    max_response_time: 10.seconds,
    max_hourly_cost: 10.00, # $10

    # Retention
    metrics_retention_days: 30,
    detailed_logs_retention_days: 7,

    # Reporting
    daily_reports: true,
    weekly_summaries: true,
    error_notifications: true
  }

  # Security Configuration
  SECURITY_CONFIG = {
    # Content Filtering
    max_query_length: 2000,
    max_response_length: 5000,
    filter_sensitive_content: true,

    # Rate Limiting
    max_requests_per_user_per_minute: 30,
    max_documents_per_user: 1000,
    max_chat_sessions_per_user: 50,

    # Validation
    validate_file_types: true,
    scan_for_malware: false, # Set to true in production
    content_safety_checks: true
  }

  # Performance Configuration
  PERFORMANCE_CONFIG = {
    # Background Jobs
    embedding_queue_priority: 5,
    chat_queue_priority: 1,
    text_extraction_queue_priority: 3,

    # Database
    batch_size: 100,
    connection_pool_size: 25,
    query_timeout: 30.seconds,

    # Memory Management
    max_memory_per_worker: 512.megabytes,
    garbage_collection_frequency: 100,

    # Optimization
    preload_embeddings: false,
    eager_load_associations: true,
    use_database_indexes: true
  }

  # Feature Flags
  FEATURE_FLAGS = {
    # AI Features
    enable_conversation_memory: true,
    enable_context_reranking: true,
    enable_embedding_caching: true,
    enable_smart_chunking: true,

    # UI Features
    enable_real_time_typing: true,
    enable_source_highlighting: true,
    enable_export_conversations: true,
    enable_advanced_search: true,

    # Analytics
    enable_user_analytics: true,
    enable_performance_monitoring: true,
    enable_cost_tracking: true,

    # Experimental
    enable_pgvector: false, # Set to true when pgvector is installed
    enable_multi_modal: false,
    enable_fine_tuning: false
  }

  # Environment-specific overrides
  case Rails.env
  when "development"
    OPENAI_CONFIG[:chat_model] = "gpt-3.5-turbo" # Cheaper for development
    CACHE_CONFIG[:embedding_ttl] = 10.minutes # Shorter cache for testing
    MONITORING_CONFIG[:track_embedding_generation] = false # Less logging in dev

  when "test"
    OPENAI_CONFIG[:max_retries] = 1
    CACHE_CONFIG[:embedding_ttl] = 1.minute
    MONITORING_CONFIG.keys.each { |key| MONITORING_CONFIG[key] = false if key.to_s.start_with?("track_") }

  when "production"
    SECURITY_CONFIG[:scan_for_malware] = true
    SECURITY_CONFIG[:content_safety_checks] = true
    PERFORMANCE_CONFIG[:preload_embeddings] = true
    FEATURE_FLAGS[:enable_pgvector] = true # Should be enabled in production
  end

  # Validation
  def self.validate_config!
    # Check required environment variables
    required_env_vars = %w[OPENAI_API_KEY]
    missing_vars = required_env_vars.select { |var| ENV[var].blank? }

    if missing_vars.any?
      raise "Missing required environment variables: #{missing_vars.join(', ')}"
    end

    # Validate model availability
    if Rails.env.production? && !openai_api_key_valid?
      raise "Invalid OpenAI API key or insufficient permissions"
    end

    # Check database configuration
    unless ActiveRecord::Base.connection.adapter_name == "PostgreSQL"
      Rails.logger.warn "PostgreSQL is recommended for optimal performance with vector operations"
    end

    Rails.logger.info "DocuSense configuration validated successfully"
  end

  def self.openai_api_key_valid?
    # Simple validation - in production you might want more thorough checks
    api_key = Rails.application.credentials.openai&.[](:api_key) || ENV["OPENAI_API_KEY"]
    api_key.present? && api_key.start_with?("sk-")
  end

  # Helper methods
  def self.embedding_model
    OPENAI_CONFIG[:embedding_model]
  end

  def self.chat_model
    OPENAI_CONFIG[:chat_model]
  end

  def self.max_chunk_size
    DOCUMENT_CONFIG[:default_chunk_size]
  end

  def self.similarity_threshold
    CHAT_CONFIG[:similarity_threshold]
  end

  def self.feature_enabled?(feature)
    FEATURE_FLAGS[feature] == true
  end
end

# Validate configuration on startup
DocusenseConfig.validate_config! unless Rails.env.test?
