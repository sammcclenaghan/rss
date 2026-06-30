# frozen_string_literal: true

module PostsHelper
  def post_date(timestamp)
    Time.at(timestamp).strftime("%Y/%-m/%-d")
  end

  def current_view_title
    if @selected_feed.present? && @display_feeds.length == 1
      @display_feeds.first.name
    elsif @tag.present?
      @tag.capitalize
    elsif @starred_only
      "Starred"
    elsif @unread_only
      "Unread"
    else
      "All Posts"
    end
  end

  def search_scope_path
    if @tag.present?
      tag_posts_path(@tag)
    elsif @selected_feed.present?
      feed_posts_path(Feed::Config.encode_feed_url(@selected_feed))
    else
      root_path
    end
  end

  def filter_path(filter)
    query = request.query_parameters.except("page", "unread", "starred")
    query["unread"] = "1" if filter == :unread
    query["starred"] = "1" if filter == :starred
    query.empty? ? request.path : "#{request.path}?#{query.to_query}"
  end

  def content_tab_class(filter)
    class_names(
      "rounded-md px-3 py-1 transition-colors",
      "bg-background font-semibold text-foreground shadow-sm": filter_active?(filter),
      "text-muted-foreground hover:text-foreground": !filter_active?(filter)
    )
  end

  def sidebar_nav_class(active)
    class_names(
      "flex items-center gap-2.5 rounded-md px-2 py-1.5 text-sm font-medium transition-colors",
      "bg-sidebar-accent text-sidebar-accent-foreground": active,
      "text-sidebar-foreground hover:bg-sidebar-accent hover:text-sidebar-accent-foreground": !active
    )
  end

  def format_post_description(post)
    ContentFilters::PostDescription.apply(post.description, base_url: post.url)
  end

  def post_link(post)
    proxy = post.feed_config&.proxy
    proxy.present? ? Ezproxy.rewrite(post.url, host: proxy) : post.url
  end

  private

  def filter_active?(filter)
    case filter
    when :unread  then @unread_only
    when :starred then @starred_only
    else !@unread_only && !@starred_only
    end
  end
end
