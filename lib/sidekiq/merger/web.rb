require "sidekiq/web"

module Sidekiq::Merger::Web
  VIEWS = File.expand_path("views", File.dirname(__FILE__))

  def self.registered(app)
    app.get "/merges" do
      @merges = Sidekiq::Merger::Merge.all
      erb File.read(File.join(VIEWS, "index.erb")), locals: { view_path: VIEWS }
    end

    app.post "/merges/:full_merge_key/delete" do
      full_merge_key = URI.decode_www_form_component params[:full_merge_key]
      merge = Sidekiq::Merger::Merge.initialize_with_full_merge_key(full_merge_key)
      merge.delete_all
      redirect "#{root_path}/merges"
    end
  end
end

Sidekiq::Web.register(Sidekiq::Merger::Web)
Sidekiq::Web.tabs["Merges"] = "merges"
