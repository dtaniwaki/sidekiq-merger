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

if Sidekiq.server?
  task = Sidekiq::Merger.create_task
  task.execute
end
