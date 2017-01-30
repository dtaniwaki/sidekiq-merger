require "spec_helper"

describe Sidekiq::Merger do
  it "has a version number" do
    expect(Sidekiq::Merger::VERSION).not_to be nil
  end
end
