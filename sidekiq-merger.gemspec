# coding: utf-8
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "sidekiq/merger/version"

Gem::Specification.new do |spec|
  spec.name          = "sidekiq-merger"
  spec.version       = Sidekiq::Merger::VERSION
  spec.platform      = Gem::Platform::RUBY
  spec.authors       = ["dtaniwaki"]
  spec.email         = ["daisuketaniwaki@gmail.com"]

  spec.summary       = "Sidekiq merger plugin"
  spec.description   = "Merge sidekiq jobs."
  spec.homepage      = "https://github.com/dtaniwaki/sidekiq-merger"
  spec.license = "MIT"

  spec.files = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  spec.executables   = `git ls-files -- bin/*`.split("\n").map { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.required_ruby_version = [">= 2.2.2", "< 2.6"]

  spec.add_development_dependency "rake", ">= 10.0", "< 13"
  spec.add_development_dependency "rspec", ">= 3.0", "< 4"
  spec.add_development_dependency "simplecov", "~> 0.12"
  spec.add_development_dependency "timecop", "~> 0.8"
  spec.add_development_dependency "rubocop", "~> 0.47"
  spec.add_development_dependency "coveralls", "~> 0.8"
  spec.add_development_dependency "appraisal"

  spec.add_runtime_dependency "sidekiq", ">= 4.0", "< 6"
  spec.add_runtime_dependency "concurrent-ruby", "~> 1.0"
  spec.add_runtime_dependency "activesupport", ">= 3.2", "< 6"
end
