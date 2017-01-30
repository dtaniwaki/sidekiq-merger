require_relative "redis"
require "active_support/core_ext/hash/indifferent_access"

class Sidekiq::Merger::Batch
  class << self
    def all
      redis = Sidekiq::Merger::Redis.new

      redis.all.map do |full_batch_key|
        keys = full_batch_key.split(":")
        raise "Invalid batch key" if keys.size < 3
        worker_class = keys[0].camelize.constantize
        queue = keys[1]
        batch_key = keys[2]
        new(worker_class, queue, batch_key, redis: redis)
      end
    end

    def initialize_with_args(worker_class, queue, args, options = {})
      new(worker_class, queue, batch_key(worker_class, args), options)
    end

    def batch_key(worker_class, args)
      options = get_options(worker_class)
      batch_key = options["key"]
      if batch_key.respond_to?(:call)
        batch_key.call(args)
      else
        batch_key
      end
    end

    def get_options(worker_class)
      (worker_class.get_sidekiq_options["merger"] || {}).with_indifferent_access
    end
  end

  attr_reader :worker_class, :queue, :batch_key

  def initialize(worker_class, queue, batch_key, redis: Sidekiq::Merger::Redis.new)
    @worker_class = worker_class
    @queue = queue
    @batch_key = batch_key
    @redis = redis
  end

  def add(args, execution_time)
    @redis.push(full_batch_key, args, execution_time)
  end

  def delete(args)
    @redis.delete(full_batch_key, args)
  end

  def size
    @redis.batch_size(full_batch_key)
  end

  def flush
    msgs = []

    if @redis.lock(full_batch_key, Sidekiq::Merger::Config.lock_ttl)
      msgs = @redis.pluck(full_batch_key)
    end

    unless msgs.empty?
      Sidekiq::Client.push(
        "class" => worker_class,
        "queue" => queue,
        "args" => msgs
      )
    end
  end

  def can_flush?
    !execution_time.nil? && execution_time < Time.now
  end

  def full_batch_key
    @full_batch_key ||= [worker_class.name.to_s.underscore, queue, batch_key].join(":")
  end

  def execution_time
    @execution_time ||= @redis.execution_time(full_batch_key)
  end

  def ==(other)
    self.worker_class == other.worker_class &&
    self.queue == other.queue &&
    self.batch_key == other.batch_key
  end

  private

  def options
    @options ||= self.class.get_options(worker_class)
  rescue NameError
    {}
  end
end
