require "spec_helper"

describe Sidekiq::Merger::LoggingObserver do
  subject { described_class.new(logger) }
  let(:logger) { Logger.new("/dev/null") }
  let(:now) { Time.now }
  before { Timecop.freeze(now) }

  describe "#update" do
    it "logs a timeout" do
      expect(logger).to receive(:error).with("[Sidekiq::Merger] Execution timed out\n")
      subject.update(now, nil, Concurrent::TimeoutError.new)
    end
    it "logs an error" do
      expect(logger).to receive(:error).with("[Sidekiq::Merger] Execution failed with error foo\n")
      subject.update(now, nil, "foo")
    end
  end
end
