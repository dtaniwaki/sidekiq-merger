require "sidekiq/web"

module Sidekiq::Merger::Web
  VIEWS = File.expand_path("views", File.dirname(__FILE__))

  def self.registered(app)
    app.get "/merger" do
      @batches = Sidekiq::Merger::Batch.all
      erb File.read(File.join(VIEWS, "index.html.erb")), locals: { view_path: VIEWS }
    end

    app.post "/merger/*/delete" do |full_merge_key|
      batch = Sidekiq::Merger::Batch.initialize_with_full_merge_key(full_merge_key)
      batch.delete
      redirect "#{root_path}/merger"
    end
  end
end

Sidekiq::Web.register(Sidekiq::Merger::Web)
Sidekiq::Web.tabs["Merger"] = "merger"
