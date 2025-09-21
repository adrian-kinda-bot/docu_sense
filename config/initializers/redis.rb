# Redis configuration for caching
redis_url = ENV.fetch("REDIS_URL", "redis://localhost:6379/0")

# Configure Redis connection pool
Redis.current = Redis.new(
  url: redis_url,
  timeout: 1,
  reconnect_attempts: 1
)

# Test Redis connection on startup
begin
  Redis.current.ping
  Rails.logger.info "✓ Redis connection established successfully"
rescue Redis::CannotConnectError => e
  Rails.logger.error "✗ Failed to connect to Redis: #{e.message}"
end
