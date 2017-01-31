require_relative "./sidekiq"
require "sinatra/base"
require "sidekiq/web"

class App < Sinatra::Application
  get "/add" do
    n = rand(100)
    SomeWorker.perform_in(60, n)
    status 200
    body "Added #{n}"
  end
end
