require "sidekiq"
require "sidekiq-merger"
require_relative "./some_worker"
require_relative "./unique_worker"

Sidekiq.configure_client do |config|
  config.redis = { url: "redis://#{ENV["REDIS_HOST"]}:#{ENV["REDIS_PORT"]}" }
end

Sidekiq.configure_server do |config|
  config.redis = { url: "redis://#{ENV["REDIS_HOST"]}:#{ENV["REDIS_PORT"]}" }
end
