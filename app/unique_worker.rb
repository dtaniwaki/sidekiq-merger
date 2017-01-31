class UniqueWorker
  include Sidekiq::Worker

  sidekiq_options merger: { key: "foo", unique: true }

  def perform(*ids)
    puts "Get IDs: #{ids.inspect}"
  end
end
