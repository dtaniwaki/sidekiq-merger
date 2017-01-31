class Sidekiq::Merger::Flusher
  def initialize(logger)
    @logger = logger
  end

  def flush
    merges = Sidekiq::Merger::Merge.all.select(&:can_flush?)
    unless merges.empty?
      @logger.info(
        "[Sidekiq::Merger] Trying to flush merged queues: #{merges.map(&:full_merge_key).join(",")}"
      )
      merges.each(&:flush)
    end
  end
end
