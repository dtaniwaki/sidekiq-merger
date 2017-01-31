require "./app"
require "sidekiq/web"
require "sidekiq/merger/web"

run Rack::URLMap.new("/" => App, "/sidekiq" => Sidekiq::Web)
