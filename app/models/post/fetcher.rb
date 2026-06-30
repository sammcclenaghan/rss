# frozen_string_literal: true

class Post
  # Loads the latest posts for a set of configured feeds, attaching each
  # post's ConfiguredFeed presentation metadata and read state.
  class Fetcher
    def latest(feed_list:, page: 1, query: nil, unread_only: false, starred_only: false)
      return [] if feed_list.feed_ids.empty?

      posts = Post.for_feeds(feed_list.feed_ids)
      posts = posts.matching(query) if query.present?
      posts = posts.unread if unread_only
      posts = posts.starred if starred_only
      posts = posts.page(page, Rails.configuration.x.rss.posts_per_page).to_a

      attach_feed_config(posts, feed_list)
      attach_read_state(posts)
      attach_starred_state(posts)
      posts
    end

    private

    def attach_feed_config(posts, feed_list)
      by_id = feed_list.mapped_by_id
      posts.each { |post| post.feed_config = by_id[post.feed_id] }
    end

    def attach_read_state(posts)
      return if posts.empty?

      read_ids = ReadPost.where(post_id: posts.map(&:id)).pluck(:post_id).to_set
      posts.each { |post| post.read_state = read_ids.include?(post.id) }
    end

    def attach_starred_state(posts)
      return if posts.empty?

      starred_ids = StarredPost.where(post_id: posts.map(&:id)).pluck(:post_id).to_set
      posts.each { |post| post.starred_state = starred_ids.include?(post.id) }
    end
  end
end
