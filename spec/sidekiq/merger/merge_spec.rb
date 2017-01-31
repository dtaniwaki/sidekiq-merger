require "spec_helper"

describe Sidekiq::Merger::Merge do
  subject { described_class.new(worker_class, queue, "foo", redis: redis) }
  let(:redis) { Sidekiq::Merger::Redis.new }
  let(:queue) { "queue" }
  let(:now) { Time.now }
  let(:execution_time) { now + 10.seconds }
  let(:options) { { key: -> (args) { args.to_json } } }
  let(:worker_class) do
    local_options = options
    Class.new do
      include Sidekiq::Worker

      sidekiq_options merger: local_options

      def self.name
        "name"
      end

      def perform(args)
      end
    end
  end
  before { Timecop.freeze(now) }

  describe ".all" do
    it "returns all the keys" do
      redis.redis do |conn|
        conn.sadd("sidekiq-merger:merges", "string:foo:xxx")
        conn.sadd("sidekiq-merger:merges", "numeric:bar:yyy")
      end

      expect(described_class.all).to contain_exactly(
        described_class.new(String, "foo", "xxx"),
        described_class.new(Numeric, "bar", "yyy")
      )
    end

    context "including invalid key" do
      it "raises an error" do
        redis.redis do |conn|
          conn.sadd("sidekiq-merger:merges", "string:foo:xxx")
          conn.sadd("sidekiq-merger:merges", "invalid")
        end
        expect {
          described_class.all
        }.to raise_error RuntimeError, "Invalid merge key"
      end
    end
  end

  describe ".initialize_with_args" do
    it "provides merge_key from args" do
      expect(described_class).to receive(:new).with(worker_class, queue, "[1,2,3]", anything)
      described_class.initialize_with_args(worker_class, queue, [1, 2, 3])
    end
    it "passes options" do
      expect(described_class).to receive(:new).with(worker_class, queue, anything, { redis: 1 })
      described_class.initialize_with_args(worker_class, queue, anything, redis: 1)
    end
  end

  describe "#add" do
    it "adds the args in lazy merge" do
      expect(redis).to receive(:push).with("name:queue:foo", [1, 2, 3], execution_time, unique: false)
      subject.add([1, 2, 3], execution_time)
    end
    context "with unique option" do
      let(:options) { { key: -> (args) { args.to_json }, unique: true } }
      it "adds the args in lazy merge" do
        expect(redis).to receive(:push).with("name:queue:foo", [1, 2, 3], execution_time, unique: true)
        subject.add([1, 2, 3], execution_time)
      end
    end
  end

  describe "#delete" do
    it "adds the args in lazy merge" do
      expect(redis).to receive(:delete).with("name:queue:foo", [1, 2, 3])
      subject.delete([1, 2, 3])
    end
  end

  describe "#size" do
  end

  describe "#flush" do
    before do
      subject.add([1, 2, 3], execution_time)
      subject.add([2, 3, 4], execution_time)
    end
    it "flushes all the args" do
      expect(Sidekiq::Client).to receive(:push).with(
        "class" => worker_class,
        "queue" => queue,
        "args" => a_collection_containing_exactly([1, 2, 3], [2, 3, 4])
      )

      subject.flush
    end
  end

  describe "#can_flush?" do
    context "it has not get anything in merge" do
      it "returns false" do
        expect(subject.can_flush?).to eq false
      end
    end
    context "it has not passed the execution time" do
      it "returns false" do
        subject.add([], execution_time)
        expect(subject.can_flush?).to eq false
      end
    end
    context "it has passed the execution time" do
      it "returns true" do
        subject.add([], execution_time)
        Timecop.travel(10.seconds)
        expect(subject.can_flush?).to eq true
      end
    end
  end

  describe "#full_merge_key" do
    it "returns full merge key" do
      expect(subject.full_merge_key).to eq "name:queue:foo"
    end
  end
end
