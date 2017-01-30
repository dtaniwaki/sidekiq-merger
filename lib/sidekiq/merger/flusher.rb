class Sidekiq::Merger::Flusher
  def initialize(logger)
    @logger = logger
  end

  def flush
    batches = Sidekiq::Merger::Batch.all.select(&:can_flush?)
    unless batches.empty?
      @logger.info(
        "[Sidekiq::Merger] Trying to flush batched queues: #{batches.map(&:full_batch_key).join(",")}"
      )
      batches.each(&:flush)
    end
  end
end
