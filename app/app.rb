require_relative "./sidekiq"
require "sinatra/base"
require "sidekiq/web"

class App < Sinatra::Application
  get "/some_worker" do
    n = rand(10)
    SomeWorker.perform_in(60, n)
    status 200
    body "Added #{n}"
  end

  get "/unique_worker" do
    n = rand(10)
    UniqueWorker.perform_in(60, n)
    status 200
    body "Added #{n}"
  end
end
