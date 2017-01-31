require "./app"

run Rack::URLMap.new("/" => App, "/sidekiq" => Sidekiq::Web)
