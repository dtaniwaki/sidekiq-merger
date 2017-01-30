require "active_support/core_ext/module/delegation"

module Sidekiq
  module Merger
    class Redis
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
            conn.eval(script, [], [batches_key, msg_key("*"), lock_key("*")])
          end
        end

        def batches_key
          "#{KEY_PREFIX}:batches"
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
        redis do |conn|
          conn.multi do
            conn.sadd(batches_key, key)
            conn.setnx(time_key(key), execution_time.to_json)
            conn.sadd(msg_key(key), msg.to_json)
          end
        end
      end

      def delete(key, msg)
        redis { |conn| conn.srem(msg_key(key), msg.to_json) }
      end

      def execution_time(key)
        redis { |conn| Time.parse(conn.get(time_key(key))) rescue nil }
      end

      def batch_size(key)
        redis { |conn| conn.scard(msg_key(key)) }
      end

      def exists?(key, msg)
        redis { |conn| conn.sismember(msg_key(key), msg.to_json) }
      end

      def all
        redis { |conn| conn.smembers(batches_key) }
      end

      def lock(key, ttl)
        redis { |conn| conn.set(lock_key(key), true, nx: true, ex: ttl) }
      end

      def get(key)
        msgs = []
        redis do |conn|
          msgs = conn.smembers(msg_key(key))
        end
        msgs.map { |msg| JSON.parse(msg) }
      end

      def pluck(key)
        msgs = []
        redis do |conn|
          msgs = conn.smembers(msg_key(key))
          conn.del(msg_key(key))
          conn.del(time_key(key))
          conn.srem(batches_key, key)
        end
        msgs.map { |msg| JSON.parse(msg) }
      end

      def delete_all(key)
        redis do |conn|
          conn.del(msg_key(key))
          conn.del(time_key(key))
          conn.del(lock_key(key))
          conn.srem(batches_key, key)
        end
      end

      private

      delegate :batches_key, :msg_key, :time_key, :lock_key, :redis, to: "self.class"
    end
  end
end
