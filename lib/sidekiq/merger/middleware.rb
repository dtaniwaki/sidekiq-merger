require_relative "merge"

class Sidekiq::Merger::Middleware
  def call(worker_class, msg, queue, _ = nil)
    return yield if defined?(Sidekiq::Testing) && Sidekiq::Testing.inline?

    worker_class = worker_class.camelize.constantize if worker_class.is_a?(String)
    options = worker_class.get_sidekiq_options

    merger_enabled = options.key?("merger")

    if merger_enabled && !msg["at"].nil? && msg["at"].to_f > Time.now.to_f
      Sidekiq::Merger::Merge
        .initialize_with_args(worker_class, queue, msg["args"])
        .add(msg["args"], msg["at"])
      false
    else
      msg["args"] = [msg["args"]] unless msg.delete("merged")
      yield
    end
  end
end
