require "spec_helper"

describe Sidekiq::Merger::Merge, worker_class: true do
  subject { described_class.new(worker_class, queue, args, redis: redis) }
  let(:args) { "foo" }
  let(:redis) { Sidekiq::Merger::Redis.new }
  let(:queue) { "queue" }
  let(:now) { Time.now }
  let(:execution_time) { now + 10.seconds }
  let(:worker_options) { { key: -> (args) { args.to_json } } }
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

  describe ".merge_key" do
    let(:args) { "foo" }
    let(:worker_options) { {} }
    it "returns an empty string" do
      expect(described_class.merge_key(worker_class, args)).to eq ""
    end
    context "string key" do
      let(:worker_options) { { key: "bar" } }
      it "returns the string" do
        expect(described_class.merge_key(worker_class, args)).to eq "bar"
      end
    end
    context "other type key" do
      let(:worker_options) { { key: [1, 2, 3] } }
      it "returns nil" do
        expect(described_class.merge_key(worker_class, args)).to eq "[1,2,3]"
      end
    end
    context "proc key" do
      let(:args) { [1, 2, 3] }
      let(:worker_options) { { key: -> (args) { args[0].to_s } } }
      it "returns the result of the proc" do
        expect(described_class.merge_key(worker_class, args)).to eq "1"
      end
      context "non-string result" do
        let(:worker_options) { { key: -> (args) { args[0] } } }
        it "returns nil" do
          expect(described_class.merge_key(worker_class, args)).to eq "1"
        end
      end
    end
  end

  describe "#add" do
    it "adds the args in lazy merge" do
      expect(redis).to receive(:push_message).with("some_worker:queue:foo", [1, 2, 3], execution_time)
      subject.add([1, 2, 3], execution_time)
    end
    context "with unique option" do
      let(:worker_options) { { key: -> (args) { args.to_json }, unique: true } }
      it "adds the args in lazy merge" do
        expect(redis).to receive(:push_message).with("some_worker:queue:foo", [1, 2, 3], execution_time)
        subject.add([1, 2, 3], execution_time)
      end
      context "the args has alredy been added" do
        before { subject.add([1, 2, 3], execution_time) }
        it "adds the args in lazy merge" do
          expect(redis).not_to receive(:push_message)
          subject.add([1, 2, 3], execution_time)
        end
      end
    end
  end

  describe "#delete" do
    it "adds the args in lazy merge" do
      expect(redis).to receive(:delete_message).with("some_worker:queue:foo", [1, 2, 3])
      subject.delete([1, 2, 3])
    end
  end

  describe "#delete_all" do
    before do
      subject.add([1, 2, 3], execution_time)
      subject.add([2, 3, 4], execution_time)
    end
    it "deletes all" do
      expect {
        subject.delete_all
      }.to change { subject.size }.from(2).to(0)
    end
  end

  describe "#size" do
    before do
      subject.add([1, 2, 3], execution_time)
      subject.add([2, 3, 4], execution_time)
    end
    it "returns the size" do
      expect(subject.size).to eq 2
    end
  end

  describe "#all_args" do
    before do
      subject.add([1, 2, 3], execution_time)
      subject.add([2, 3, 4], execution_time)
    end
    it "returns all args" do
      expect(subject.all_args).to contain_exactly [1, 2, 3], [2, 3, 4]
    end
  end

  describe "#flush" do
    context "when no batch_size is configured" do
      before do
        subject.add([1, 2, 3], execution_time)
        subject.add([2, 3, 4], execution_time)
      end
      it "flushes all the args" do
        expect(Sidekiq::Client).to receive(:push).with(
          "class" => worker_class,
          "queue" => queue,
          "args" => a_collection_containing_exactly([1, 2, 3], [2, 3, 4]),
          "merged" => true
        )
  
        subject.flush
      end
    end

    context "when batch_size is configured to 2" do
      let(:worker_options) { { key: -> (args) { args.to_json }, batch_size: 2 } }
      before do
        subject.add([1, 2, 3], execution_time)
        subject.add([2, 3, 4], execution_time)
        subject.add([3, 4, 5], execution_time)
        subject.add([4, 5, 6], execution_time)
      end
      it "flushes all the args" do
        expect(Sidekiq::Client).to receive(:push).with(
          "class" => worker_class,
          "queue" => queue,
          "args" => a_collection_containing_exactly([1, 2, 3], [2, 3, 4]),
          "merged" => true
        )

        expect(Sidekiq::Client).to receive(:push).with(
          "class" => worker_class,
          "queue" => queue,
          "args" => a_collection_containing_exactly([3, 4, 5], [4, 5, 6]),
          "merged" => true
        )

        subject.flush
      end
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
      expect(subject.full_merge_key).to eq "some_worker:queue:foo"
    end
  end
end
