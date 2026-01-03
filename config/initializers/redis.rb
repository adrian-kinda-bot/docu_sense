# Redis configuration
# Note: Redis.current is deprecated in redis gem 5.0+
# Rails cache and Sidekiq manage their own Redis connections
# This initializer is for direct Redis access if needed

# Create a Redis instance for direct access (if needed)
# Store it in a constant or module for access throughout the app
module RedisConnection
  def self.client
    @client ||= Redis.new(
      url: ENV.fetch("REDIS_URL", "redis://localhost:6379/0"),
      timeout: 1,
      reconnect_attempts: 1
    )
  end
end

# Test Redis connection on startup
begin
  RedisConnection.client.ping
  Rails.logger.info "✓ Redis connection established successfully"
rescue Redis::CannotConnectError => e
  Rails.logger.error "✗ Failed to connect to Redis: #{e.message}"
rescue => e
  Rails.logger.warn "⚠ Redis connection test skipped: #{e.message}"
end
