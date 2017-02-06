require "spec_helper"

describe Sidekiq::Merger do
  it "has a version number" do
    expect(described_class::VERSION).not_to be nil
  end
  describe ".create_task" do
    it "starts a monitoring task" do
      task = described_class.create_task
      expect(task).to be_a Concurrent::TimerTask
      task.shutdown
    end
  end
  describe ".configure" do
    it 'yields to the config' do
      expect { |b| described_class.configure(&b) }.to yield_with_args(described_class.config)
    end
  end
  describe ".config" do
    it "returns a config" do
      expect(described_class.config).to be_a Sidekiq::Merger::Config
    end
    context "called twice" do
      it "returns the same config instance" do
        expect(described_class.config).to be described_class.config
      end
    end
  end
end
