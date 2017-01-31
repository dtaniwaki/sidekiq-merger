require "spec_helper"

describe Sidekiq::Merger::Flusher do
  subject { described_class.new(Sidekiq.logger) }

  describe "#call" do
    let(:active_merge) { double(full_merge_key: "active", can_flush?: true, flush: nil) }
    let(:inactive_merge) { double(full_merge_key: "inactive", can_flush?: false, flush: nil) }
    let(:merges) { [active_merge, inactive_merge] }
    it "adds the args to the merge" do
      allow(Sidekiq::Merger::Merge).to receive(:all).and_return merges
      expect(active_merge).to receive(:flush)
      expect(inactive_merge).not_to receive(:flush)

      subject.flush
    end
  end
end
