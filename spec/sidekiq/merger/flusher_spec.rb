require "spec_helper"

describe Sidekiq::Merger::Flusher do
  subject { described_class.new(Sidekiq.logger) }

  describe "#call" do
    let(:active_batch) { double(full_batch_key: "active", can_flush?: true, flush: nil) }
    let(:inactive_batch) { double(full_batch_key: "inactive", can_flush?: false, flush: nil) }
    let(:batches) { [active_batch, inactive_batch] }
    it "adds the args to the batch" do
      allow(Sidekiq::Merger::Batch).to receive(:all).and_return batches
      expect(active_batch).to receive(:flush)
      expect(inactive_batch).not_to receive(:flush)

      subject.flush
    end
  end
end
