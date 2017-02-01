require "sidekiq"
require "concurrent"
require_relative "merger/version"
require_relative "merger/middleware"
require_relative "merger/config"
require_relative "merger/flusher"
require_relative "merger/logging_observer"

module Sidekiq::Merger
  LOGGER_TAG = self.name.freeze

  class << self
    attr_accessor :logger

    def create_task
      interval = Sidekiq::Merger::Config.poll_interval
      observer = Sidekiq::Merger::LoggingObserver.new(logger)
      flusher = Sidekiq::Merger::Flusher.new(logger)
      task = Concurrent::TimerTask.new(
        execution_interval: interval
      ) { flusher.flush }
      task.add_observer(observer)
      task
    end
  end

  self.logger = Sidekiq.logger
end
