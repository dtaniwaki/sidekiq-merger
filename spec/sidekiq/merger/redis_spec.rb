require "spec_helper"

describe Sidekiq::Merger::Redis do
  subject { described_class.new }
  let(:now) { Time.now }
  let(:execution_time) { now + 10.seconds }
  before { Timecop.freeze(now) }

  describe ".purge" do
    it "cleans up all the keys" do
      described_class.redis do |conn|
        conn.sadd("sidekiq-merger:batches", "test")
        conn.set("sidekiq-merger:msg:foo", "test")
        conn.set("sidekiq-merger:lock:foo", "test")
      end

      described_class.purge!

      described_class.redis do |conn|
        expect(conn.smembers("sidekiq-merger:batches")).to be_empty
        expect(conn.keys("sidekiq-merger:msg:*")).to be_empty
        expect(conn.keys("sidekiq-merger:lock:*")).to be_empty
      end
    end
  end

  describe "#push" do
    it "pushes the args" do
      subject.push("foo", [1, 2, 3], execution_time)
      described_class.redis do |conn|
        expect(conn.smembers("sidekiq-merger:batches")).to contain_exactly "foo"
        expect(conn.keys("sidekiq-merger:time:*")).to contain_exactly "sidekiq-merger:time:foo"
        expect(conn.keys("sidekiq-merger:msg:*")).to contain_exactly "sidekiq-merger:msg:foo"
        expect(conn.smembers("sidekiq-merger:msg:foo")).to contain_exactly "[1,2,3]"
      end
    end
    it "sets the execution time" do
      subject.push("foo", [1, 2, 3], execution_time)
      described_class.redis do |conn|
        expect(conn.get("sidekiq-merger:time:foo")).to eq execution_time.to_json
      end
    end

    context "the batch key already exists" do
      before do
        subject.push("foo", [1, 2, 3], execution_time)
      end
      it "pushes the args" do
        subject.push("foo", [2, 3, 4], execution_time + 1.hour)
        described_class.redis do |conn|
          expect(conn.smembers("sidekiq-merger:batches")).to contain_exactly "foo"
          expect(conn.keys("sidekiq-merger:time:*")).to contain_exactly "sidekiq-merger:time:foo"
          expect(conn.keys("sidekiq-merger:msg:*")).to contain_exactly "sidekiq-merger:msg:foo"
          expect(conn.smembers("sidekiq-merger:msg:foo")).to contain_exactly "[1,2,3]", "[2,3,4]"
        end
      end
      it "does not update the execution time" do
        subject.push("foo", [2, 3, 4], execution_time + 1.hour)
        described_class.redis do |conn|
          expect(conn.get("sidekiq-merger:time:foo")).to eq execution_time.to_json
        end
      end
    end

    context "the args has already been pushed" do
      before do
        subject.push("foo", [1, 2, 3], execution_time)
      end
      it "does not push the args" do
        subject.push("foo", [1, 2, 3], execution_time + 1.hour)
        described_class.redis do |conn|
          expect(conn.smembers("sidekiq-merger:batches")).to contain_exactly "foo"
          expect(conn.keys("sidekiq-merger:time:*")).to contain_exactly "sidekiq-merger:time:foo"
          expect(conn.keys("sidekiq-merger:msg:*")).to contain_exactly "sidekiq-merger:msg:foo"
          expect(conn.smembers("sidekiq-merger:msg:foo")).to contain_exactly "[1,2,3]"
        end
      end
      it "does not update the execution time" do
        subject.push("foo", [1, 2, 3], execution_time + 1.hour)
        described_class.redis do |conn|
          expect(conn.get("sidekiq-merger:time:foo")).to eq execution_time.to_json
        end
      end
    end

    context "other batch key already exists" do
      before do
        subject.push("foo", [1, 2, 3], execution_time)
      end
      it "does not interfere the other batch" do
        subject.push("bar", [2, 3, 4], execution_time + 1.hour)
        described_class.redis do |conn|
          expect(conn.smembers("sidekiq-merger:batches")).to contain_exactly "foo", "bar"
          expect(conn.keys("sidekiq-merger:time:*")).to contain_exactly "sidekiq-merger:time:foo", "sidekiq-merger:time:bar"
          expect(conn.keys("sidekiq-merger:msg:*")).to contain_exactly "sidekiq-merger:msg:foo", "sidekiq-merger:msg:bar"
          expect(conn.smembers("sidekiq-merger:msg:foo")).to contain_exactly "[1,2,3]"
          expect(conn.smembers("sidekiq-merger:msg:bar")).to contain_exactly "[2,3,4]"
        end
      end
      it "sets the execution time" do
        subject.push("bar", [2, 3, 4], execution_time + 1.hour)
        described_class.redis do |conn|
          expect(conn.get("sidekiq-merger:time:foo")).to eq execution_time.to_json
          expect(conn.get("sidekiq-merger:time:bar")).to eq (execution_time + 1.hour).to_json
        end
      end
    end
  end

  describe "#delete" do
  end

  describe "#batch_size" do
  end

  describe "#exists?" do
  end

  describe "#all" do
  end

  describe "#lock" do
  end

  describe "#get" do
  end

  describe "#pluck" do
    before do
      subject.push("bar", [1, 2, 3], execution_time)
      subject.push("bar", [2, 3, 4], execution_time)
    end
    it "plucks all the args" do
      expect(subject.pluck("bar")).to eq [[1, 2, 3], [2, 3, 4]]
    end
  end

  describe "#delete_all" do
  end
end
