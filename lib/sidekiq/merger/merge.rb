require_relative "redis"
require "active_support/core_ext/hash/indifferent_access"

class Sidekiq::Merger::Merge
  class << self
    def all
      redis = Sidekiq::Merger::Redis.new

      redis.all_merges.map { |full_merge_key| initialize_with_full_merge_key(full_merge_key, redis: redis) }
    end

    def initialize_with_full_merge_key(full_merge_key, options = {})
      keys = full_merge_key.split(":")
      raise "Invalid merge key" if keys.size < 3
      worker_class = keys[0].camelize.constantize
      queue = keys[1]
      merge_key = keys[2]
      new(worker_class, queue, merge_key, options)
    end

    def initialize_with_args(worker_class, queue, args, options = {})
      new(worker_class, queue, merge_key(worker_class, args), options)
    end

    def merge_key(worker_class, args)
      options = get_options(worker_class)
      merge_key = options["key"]
      if merge_key.respond_to?(:call)
        merge_key = merge_key.call(args)
      end
      merge_key = "" if merge_key.nil?
      merge_key = merge_key.to_json unless merge_key.is_a?(String)
      merge_key
    end

    def get_options(worker_class)
      (worker_class.get_sidekiq_options["merger"] || {}).with_indifferent_access
    end
  end

  attr_reader :worker_class, :queue, :merge_key

  def initialize(worker_class, queue, merge_key, redis: Sidekiq::Merger::Redis.new)
    @worker_class = worker_class
    @queue = queue
    @merge_key = merge_key
    @redis = redis
  end

  def add(args, execution_time)
    if !options[:unique] || !@redis.merge_exists?(full_merge_key, args)
      @redis.push_message(full_merge_key, args, execution_time)
    end
  end

  def delete(args)
    @redis.delete_message(full_merge_key, args)
  end

  def delete_all
    @redis.delete_merge(full_merge_key)
  end

  def size
    @redis.merge_size(full_merge_key)
  end

  def flush
    msgs = []

    if @redis.lock_merge(full_merge_key, Sidekiq::Merger::Config.lock_ttl)
      msgs = @redis.pluck_merge(full_merge_key)
    end

    unless msgs.empty?
      Sidekiq::Client.push(
        "class" => worker_class,
        "queue" => queue,
        "args" => msgs,
        "merged" => true
      )
    end
  end

  def can_flush?
    !execution_time.nil? && execution_time < Time.now
  end

  def full_merge_key
    @full_merge_key ||= [worker_class.name.to_s.underscore, queue, merge_key].join(":")
  end

  def all_args
    @redis.get_merge(full_merge_key)
  end

  def execution_time
    @execution_time ||= @redis.merge_execution_time(full_merge_key)
  end

  def ==(other)
    self.worker_class == other.worker_class &&
    self.queue == other.queue &&
    self.merge_key == other.merge_key
  end

  private

  def options
    @options ||= self.class.get_options(worker_class)
  rescue NameError
    {}
  end
end
