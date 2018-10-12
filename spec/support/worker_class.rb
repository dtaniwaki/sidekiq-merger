RSpec.shared_context "worker class", worker_class: true do
  let(:worker_options) { { key: -> (args) { "key" } } }
  let(:worker_class) do
    local_options = worker_options
    Class.new do
      include Sidekiq::Worker

      sidekiq_options merger: local_options

      def self.name
        "SomeWorker"
      end

      def self.to_s
        "SomeWorker"
      end

      def perform(*args)
      end
    end
  end
  let(:non_merge_worker_class) do
    Class.new do
      include Sidekiq::Worker

      def self.to_s
        "NonMergeWorker"
      end

      def perform(*args)
      end
    end
  end
  before :example do
    allow(Object).to receive(:const_get).with(anything).and_call_original
    allow(Object).to receive(:const_get).with("SomeWorker").and_return worker_class
    allow(Object).to receive(:const_get).with("NonMergeWorker").and_return non_merge_worker_class
  end
  around :example do |example|
    worker_class.jobs.clear
    non_merge_worker_class.jobs.clear
    begin
      example.run
    ensure
      worker_class.jobs.clear
      non_merge_worker_class.jobs.clear
    end
  end
end
