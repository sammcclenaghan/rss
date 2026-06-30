# frozen_string_literal: true

module PostsHelper
  def format_post_description(post)
    ContentFilters::PostDescription.apply(post.description, base_url: post.url)
  end

  # The link to open for a post. Routes through the feed's library EZProxy host
  # when one is configured; otherwise the original url.
  def post_link(post)
    proxy = post.feed_config&.proxy
    proxy.present? ? Ezproxy.rewrite(post.url, host: proxy) : post.url
  end
end
