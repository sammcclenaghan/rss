class PostsController < ApplicationController
  before_action :set_provider

  def index
    @display_feeds = @provider.all
    @display_feeds.reload_outdated

    render_posts_for @provider.visible
  end

  def tag
    @tag = params[:tag]
    @display_feeds = @provider.for_tag(@tag)
    @display_feeds.reload_outdated

    render_posts_for @display_feeds
  end

  def feed
    @selected_feed = Feed::Config.decode_feed_url(params[:feed])
    @display_feeds = @provider.for_url(@selected_feed)
    @display_feeds.reload_outdated

    render_posts_for @display_feeds
  end

  private
    def set_provider
      @provider = Feed::Provider.from_app_config
    end

    def render_posts_for(post_feeds)
      @page = [ params[:page].to_i, 1 ].max
      @query = params[:query].to_s
      @posts = Post::Fetcher.new.latest(feed_list: post_feeds, page: @page, query: @query)

      render :index, formats: :html
    end
end
