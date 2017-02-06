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
end
