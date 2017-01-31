require_relative "batch"

class Sidekiq::Merger::Middleware
  def call(worker_class, msg, queue, _redis_pool = nil)
    return yield if defined?(Sidekiq::Testing) && Sidekiq::Testing.inline?

    worker_class = worker_class.camelize.constantize if worker_class.is_a?(String)
    options = worker_class.get_sidekiq_options

    if !msg["at"].nil? && options.key?("merger")
      Sidekiq::Merger::Batch
        .initialize_with_args(worker_class, queue, msg["args"])
        .add(msg["args"], msg["at"])
      false
    else
      yield
    end
  end
end
