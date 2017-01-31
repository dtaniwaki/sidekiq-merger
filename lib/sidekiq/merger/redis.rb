require "active_support/core_ext/module/delegation"

class Sidekiq::Merger::Redis
  class << self
    KEY_PREFIX = "sidekiq-merger".freeze

    def purge!
      redis do |conn|
        conn.eval
        script = <<-SCRIPT
          for i=1, #ARGV do
            redis.call('del', unpack(redis.call('keys', ARGV[i])))
          end
          return true
        SCRIPT
        conn.eval(script, [], [merges_key, unique_msg_key("*"), msg_key("*"), lock_key("*")])
      end
    end

    def merges_key
      "#{KEY_PREFIX}:merges"
    end

    def unique_msg_key(key)
      "#{KEY_PREFIX}:unique_msg:#{key}"
    end

    def msg_key(key)
      "#{KEY_PREFIX}:msg:#{key}"
    end

    def time_key(key)
      "#{KEY_PREFIX}:time:#{key}"
    end

    def lock_key(key)
      "#{KEY_PREFIX}:lock:#{key}"
    end

    def redis(&block)
      Sidekiq.redis(&block)
    end
  end

  def push(key, msg, execution_time)
    msg_json = msg.to_json
    redis do |conn|
      conn.multi do
        conn.sadd(merges_key, key)
        conn.setnx(time_key(key), execution_time.to_i)
        conn.lpush(msg_key(key), msg_json)
        conn.sadd(unique_msg_key(key), msg_json)
      end
    end
  end

  def delete(key, msg)
    msg_json = msg.to_json
    redis do |conn|
      conn.multi do
        conn.srem(unique_msg_key(key), msg_json)
        conn.lrem(msg_key(key), 0, msg_json)
      end
    end
  end

  def execution_time(key)
    redis do |conn|
      t = conn.get(time_key(key))
      Time.at(t.to_i) unless t.nil?
    end
  end

  def size(key)
    redis { |conn| conn.llen(msg_key(key)) }
  end

  def exists?(key, msg)
    msg_json = msg.to_json
    redis { |conn| conn.sismember(unique_msg_key(key), msg_json) }
  end

  def all
    redis { |conn| conn.smembers(merges_key) }
  end

  def lock(key, ttl)
    redis { |conn| conn.set(lock_key(key), true, nx: true, ex: ttl) }
  end

  def get(key)
    msgs = []
    redis { |conn| msgs = conn.lrange(msg_key(key), 0, -1) }
    msgs.map { |msg| JSON.parse(msg) }
  end

  def pluck(key)
    msgs = []
    redis do |conn|
      conn.multi do
        msgs = conn.lrange(msg_key(key), 0, -1)
        conn.del(unique_msg_key(key))
        conn.del(msg_key(key))
        conn.del(time_key(key))
        conn.srem(merges_key, key)
      end
    end
    extract_future_value(msgs).map { |msg| JSON.parse(msg) }
  end

  def delete_all(key)
    redis do |conn|
      conn.multi do
        conn.del(unique_msg_key(key))
        conn.del(msg_key(key))
        conn.del(time_key(key))
        conn.del(lock_key(key))
        conn.srem(merges_key, key)
      end
    end
  end

  private

  delegate :merges_key, :msg_key, :unique_msg_key, :time_key, :lock_key, :redis, to: "self.class"

  def extract_future_value(future)
    while future.value.is_a?(Redis::FutureNotReady)
      sleep(0.001)
    end
    future.value
  end
end
