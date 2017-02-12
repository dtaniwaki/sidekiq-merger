require_relative "./sidekiq"
require "sinatra/base"
require "sinatra/cookies"
require "securerandom"
require "rack/flash"
require "sidekiq/web"
require "sidekiq-status/web"
require "sidekiq/merger/web"

class App < Sinatra::Application
  enable :sessions
  use Rack::Flash

  before do
    @queue = cookies[:queue] ||= SecureRandom.urlsafe_base64(8)
  end

  get "/" do
    erb :index
  end

  post "/some_worker/perform_in" do
    n = rand(10)
    Sidekiq::Client.push(
      "queue" => @queue,
      "class" => SomeWorker,
      "args" => [n],
      "at" => Time.now + (params[:in] || 60)
    )
    flash[:notice] = "Added #{n} to SomeWorker to Queue #{@queue}"
    redirect "/"
  end

  post "/some_worker/perform_async" do
    n = rand(10)
    Sidekiq::Client.push(
      "queue" => @queue,
      "class" => SomeWorker,
      "args" => [n]
    )
    flash[:notice] = "Added #{n} to SomeWorker to Queue #{@queue}"
    redirect "/"
  end

  post "/unique_worker/perform_in" do
    n = rand(10)
    Sidekiq::Client.push(
      "queue" => @queue,
      "class" => UniqueWorker,
      "args" => [n],
      "at" => Time.now + (params[:in] || 60)
    )
    flash[:notice] = "Added #{n} to UniqueWorker to Queue #{@queue}"
    redirect "/"
  end

  post "/unique_worker/perform_async" do
    n = rand(10)
    Sidekiq::Client.push(
      "queue" => @queue,
      "class" => UniqueWorker,
      "args" => [n]
    )
    flash[:notice] = "Added #{n} to UniqueWorker to Queue #{@queue}"
    redirect "/"
  end
end
