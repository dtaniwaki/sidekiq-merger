require "spec_helper"

describe Sidekiq::Merger::Middleware, worker_class: true do
  subject { described_class.new }
  let(:flusher) { Sidekiq::Merger::Flusher.new(Sidekiq.logger) }
  let(:queue) { "queue" }
  let(:now) { Time.now }
  before :example do
    Timecop.freeze(now)
  end

  describe "#call" do
    context "non-merger worker" do
      it "leaves args alone" do
        msg = { "args" => [1, 2, 3] }
        expect { |b| subject.call(non_merge_worker_class, msg, queue, &b) }.to yield_with_no_args
        expect(msg).to eq({ "args" => [1, 2, 3] }) #unmodified
        flusher.flush
        expect(worker_class.jobs.size).to eq 0
      end
    end
    it "adds the args to the merge" do
      subject.call(worker_class, { "args" => [1, 2, 3], "at" => (now + 10.seconds).to_f }, queue) {}
      subject.call(worker_class, { "args" => [2, 3, 4], "at" => (now + 15.seconds).to_f }, queue) {}
      flusher.flush
      expect(worker_class.jobs.size).to eq 0
      Timecop.travel(10.seconds)
      flusher.flush
      expect(worker_class.jobs.size).to eq 1
      job = worker_class.jobs[0]
      expect(job["queue"]).to eq queue
      expect(job["args"]).to contain_exactly [1, 2, 3], [2, 3, 4]
    end
    context "without at msg" do
      it "peforms now with brackets" do
        msg = { "args" => [1, 2, 3] }
        expect { |b| subject.call(worker_class, msg, queue, &b) }.to yield_with_no_args
        expect(msg).to eq({ "args" => [[1, 2, 3]] })
        flusher.flush
        expect(worker_class.jobs.size).to eq 0
      end
      context "merged msgs" do
        it "performs now" do
          msg = { "args" => [[1, 2, 3]], "merged" => true }
          expect { |b| subject.call(worker_class, msg, queue, &b) }.to yield_with_no_args
          expect(msg).to eq({ "args" => [[1, 2, 3]] })
          flusher.flush
          expect(worker_class.jobs.size).to eq 0
        end
      end
    end
    context "at is before current time" do
      it "peforms now" do
        msg = { "args" => [1, 2, 3], "at" => now.to_f }
        expect { |b| subject.call(worker_class, msg, queue, &b) }.to yield_with_no_args
        expect(msg).to eq({ "args" => [[1, 2, 3]], "at" => now.to_f })
        flusher.flush
        expect(worker_class.jobs.size).to eq 0
      end
    end
  end
end
