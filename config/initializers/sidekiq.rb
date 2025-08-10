# frozen_string_literal: true

require "sidekiq"

# Use REDIS_URL if provided, otherwise default to local Redis
REDIS_URL = ENV.fetch("REDIS_URL", "redis://127.0.0.1:6379/0")

# Fail fast if non-JSON-safe arguments are enqueued
Sidekiq.strict_args!(true)

Sidekiq.configure_server do |config|
  config.redis = { url: REDIS_URL }

  # Optional: set concurrency via env var (default Sidekiq value is fine if unset)
  if (concurrency = ENV["SIDEKIQ_CONCURRENCY"]) && concurrency.to_i > 0
    config.options[:concurrency] = concurrency.to_i
  end
end

Sidekiq.configure_client do |config|
  config.redis = { url: REDIS_URL }
end

# If any code uses ActiveJob, process those jobs via Sidekiq
Rails.application.config.active_job.queue_adapter = :sidekiq
