class SomeWorker
  include Sidekiq::Worker

  sidekiq_options merger: { key: "foo" }

  def perform(*ids)
    puts "Get IDs: #{ids.inspect}"
  end
end
