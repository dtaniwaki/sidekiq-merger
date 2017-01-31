class Sidekiq::Merger::LoggingObserver
  def initialize(logger)
    @logger = logger
  end

  def update(time, _result, ex)
    if ex.is_a?(Concurrent::TimeoutError)
      @logger.error(
        "[Sidekiq::Merger] Execution timed out\n"
      )
    elsif ex.present?
      @logger.error(
        "[Sidekiq::Merger] Execution failed with error #{ex}\n"
      )
    end
  end
end
