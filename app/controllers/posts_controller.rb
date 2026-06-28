class PostsController < ApplicationController
  before_action :set_provider

  def index
    @display_feeds = @provider.all
    @display_feeds.reload_outdated unless turbo_frame_request?

    render_posts_for @provider.visible
  end

  def tag
    @tag = params[:tag]
    @display_feeds = @provider.for_tag(@tag)
    @display_feeds.reload_outdated unless turbo_frame_request?

    render_posts_for @display_feeds
  end

  def feed
    @selected_feed = Feed::Config.decode_feed_url(params[:feed])
    @display_feeds = @provider.for_url(@selected_feed)
    @display_feeds.reload_outdated unless turbo_frame_request?

    render_posts_for @display_feeds
  end

  private
    def set_provider
      @provider = Feed::Provider.from_app_config
    end

    def render_posts_for(post_feeds)
      @page = [ params[:page].to_i, 1 ].max
      @query = params[:query].to_s
      @unread_only = params[:unread].present?
      @starred_only = params[:starred].present?
      @posts = Post::Fetcher.new.latest(
        feed_list: post_feeds, page: @page, query: @query,
        unread_only: @unread_only, starred_only: @starred_only
      )

      # Turbo Frame requests (search, pagination, unread toggle) only need
      # the frame contents — skip layout rendering and sidebar-only work.
      unless turbo_frame_request?
        @unread_counts = unread_counts_for(@display_feeds)
        load_sidebar_data
      end

      render :index, formats: :html, layout: !turbo_frame_request?
    end

    # The sidebar shows a constant, global view of every visible feed (grouped
    # into folders) regardless of the current content filter, with totals for
    # the Unread / Starred / All nav.
    def load_sidebar_data
      @sidebar_feeds = @provider.visible
      @sidebar_unread_counts = unread_counts_for(@sidebar_feeds)
      @unread_total = @sidebar_unread_counts.values.sum
      @starred_count = Post.for_feeds(@sidebar_feeds.feed_ids).starred.count
    end

    # Unread post count per feed id, for the sidebar badges.
    def unread_counts_for(feed_list)
      ids = feed_list.feed_ids
      return {} if ids.empty?

      Post.for_feeds(ids).unread.group(:feed_id).count
    end
end
