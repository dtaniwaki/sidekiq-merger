require "sidekiq"
require "concurrent"
require_relative "merger/version"
require_relative "merger/middleware"
require_relative "merger/config"
require_relative "merger/flusher"
require_relative "merger/logging_observer"

module Sidekiq::Merger
  class << self
    attr_accessor :logger
  end

  self.logger ||= Sidekiq.logger

  def logger
    self.class.logger
  end

  def start!
    interval = Sidekiq::Merger::Config.poll_interval
    observer = Sidekiq::Merger::LoggingObserver.new(logger)
    flusher = Sidekiq::Merger::Flusher.new(logger)
    task = Concurrent::TimerTask.new(
      execution_interval: interval
    ) { flusher.flush }
    task.add_observer(observer)
    logger.info(
      "[Sidekiq::Merger] Started polling batches every #{interval} seconds"
    )
    task.execute
  end
end
