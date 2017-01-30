require_relative "sidekiq/merger"

Sidekiq.configure_client do |config|
  config.client_middleware do |chain|
    chain.add Sidekiq::Merger::Middleware
  end
end

Sidekiq.configure_server do |config|
  config.client_middleware do |chain|
    chain.add Sidekiq::Merger::Middleware
  end
end

Sidekiq::Merger.start! if Sidekiq.server?
