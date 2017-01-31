require "active_support/core_ext/numeric/time"
require "sidekiq"
require "sidekiq-status"
require "sidekiq-merger"
require_relative "workers/some_worker"
require_relative "workers/unique_worker"

expiration = 30.minutes

Sidekiq.configure_client do |config|
  config.redis = { url: "redis://#{ENV["REDIS_HOST"]}:#{ENV["REDIS_PORT"]}" }
  config.client_middleware do |chain|
    chain.add Sidekiq::Status::ClientMiddleware, expiration: expiration
  end
end

Sidekiq.configure_server do |config|
  config.redis = { url: "redis://#{ENV["REDIS_HOST"]}:#{ENV["REDIS_PORT"]}" }
  config.server_middleware do |chain|
    chain.add Sidekiq::Status::ServerMiddleware, expiration: expiration
  end
  config.client_middleware do |chain|
    chain.add Sidekiq::Status::ClientMiddleware, expiration: expiration
  end
end
