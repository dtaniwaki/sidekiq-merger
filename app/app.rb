require_relative "./sidekiq"
require "sinatra/base"
require "rack/flash"
require "sidekiq/web"
require "sidekiq-status/web"
require "sidekiq/merger/web"

class App < Sinatra::Application
  enable :sessions
  use Rack::Flash

  get "/" do
    erb :index
  end

  post "/some_worker/perform_in" do
    n = rand(10)
    SomeWorker.perform_in((params[:in] || 60).to_i, n)
    flash[:notice] = "Added #{n} to SomeWorker"
    redirect "/"
  end

  post "/some_worker/perform_async" do
    n = rand(10)
    SomeWorker.perform_async(n)
    flash[:notice] = "Added #{n} to SomeWorker"
    redirect "/"
  end

  post "/unique_worker/perform_in" do
    n = rand(10)
    UniqueWorker.perform_in((params[:in] || 60).to_i, n)
    flash[:notice] = "Added #{n} to UniqueWorker"
    redirect "/"
  end

  post "/unique_worker/perform_async" do
    n = rand(10)
    UniqueWorker.perform_async(n)
    flash[:notice] = "Added #{n} to UniqueWorker"
    redirect "/"
  end
end
