require "spec_helper"

describe Sidekiq::Merger::Middleware do
  subject { described_class.new }
  let(:flusher) { Sidekiq::Merger::Flusher.new(Sidekiq.logger) }
  let(:queue) { "queue" }
  let(:now) { Time.now }
  let(:options) { { key: -> (args) { "key" } } }
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
  before :example do
    allow(Object).to receive(:const_get).with("Name").and_return worker_class
  end

  describe "#call" do
    it "adds the args to the batch" do
      subject.call(worker_class, { "args" => [1, 2, 3], "at" => now + 10.seconds }, queue) {}
      subject.call(worker_class, { "args" => [2, 3, 4], "at" => now + 15.seconds }, queue) {}
      flusher.flush
      expect(worker_class.jobs.size).to eq 0
      Timecop.travel(10.seconds)
      flusher.flush
      expect(worker_class.jobs.size).to eq 1
      job = worker_class.jobs[0]
      expect(job["queue"]).to eq queue
      expect(job["args"]).to eq [[1, 2, 3], [2, 3, 4]]
    end
    context "without at msg" do
      it "does not add the args to the batch" do
        subject.call(worker_class, { "args" => [1, 2, 3] }, queue) {}
        subject.call(worker_class, { "args" => [2, 3, 4] }, queue) {}
        flusher.flush
        expect(worker_class.jobs.size).to eq 0
      end
    end
  end
end
