$LOAD_PATH.unshift File.expand_path("../../lib", __FILE__)
require "rubygems"
require "sidekiq/testing"
require "active_support/core_ext/numeric/time"
require "timecop"
require "simplecov"
require "coveralls"

pid = Process.pid
SimpleCov.at_exit do
  SimpleCov.result.format! if Process.pid == pid
end
SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter[
  SimpleCov::Formatter::HTMLFormatter,
  Coveralls::SimpleCov::Formatter
]
SimpleCov.start

require "sidekiq/merger"

Dir[File.join(__dir__, "support", "**", "*.rb")].each { |f| require f }

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  if config.files_to_run.one?
    config.default_formatter = "doc"
  end

  config.order = :random

  Kernel.srand config.seed

  config.before :suite do
    Sidekiq::Testing.fake!
    Sidekiq::Merger.logger = nil
    Sidekiq.logger = nil
    if Redis.respond_to?(:exists_returns_integer)
      Redis.exists_returns_integer = false
    end
  end

  config.around :example do |example|
    Sidekiq::Merger::Redis.redis { |conn| conn.flushall }
    begin
      example.run
    ensure
      Sidekiq::Merger::Redis.redis { |conn| conn.flushall }
    end
  end

  config.after :example do
    Timecop.return
  end
end
