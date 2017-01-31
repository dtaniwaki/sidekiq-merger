# sidekiq-merger

[![Gem Version][gem-image]][gem-link]
[![Dependency Status][deps-image]][deps-link]
[![Build Status][build-image]][build-link]
[![Coverage Status][cov-image]][cov-link]
[![Code Climate][gpa-image]][gpa-link]

Merge sidekiq jobs occurring within specific period. This sidekiq middleware is inspired by [sidekiq-grouping](https://github.com/gzigzigzeo/sidekiq-grouping).

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'sidekiq-merger'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install sidekiq-merger

## Usage

Add merger option into your workers.

```
class YourWorker
  include Sidekiq::Worker

  sidekiq_options merger: { key: -> (args) { args[0] } }

  def perform(all_args)
    # Do something
  end
end
```

## Web UI

Add this line to your `config/routes.rb` to activate web UI:

```ruby
require "sidekiq/merger/web"
```

## Test

```bash
bundle exec rspec
```

The test coverage is available at `./coverage/index.html`.

## Lint

```bash
bundle exec rubocop
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new [Pull Request](../../pull/new/master)

## Copyright

Copyright (c) 2017 dtaniwaki. See [LICENSE](LICENSE) for details.

[gem-image]:   https://badge.fury.io/rb/sidekiq-merger.svg
[gem-link]:    http://badge.fury.io/rb/sidekiq-merger
[build-image]: https://secure.travis-ci.org/dtaniwaki/sidekiq-merger.svg
[build-link]:  http://travis-ci.org/dtaniwaki/sidekiq-merger
[deps-image]:  https://gemnasium.com/dtaniwaki/sidekiq-merger.svg
[deps-link]:   https://gemnasium.com/dtaniwaki/sidekiq-merger
[cov-image]:   https://coveralls.io/repos/dtaniwaki/sidekiq-merger/badge.png
[cov-link]:    https://coveralls.io/r/dtaniwaki/sidekiq-merger
[gpa-image]:   https://codeclimate.com/github/dtaniwaki/sidekiq-merger.svg
[gpa-link]:    https://codeclimate.com/github/dtaniwaki/sidekiq-merger

