class Post
  # Loads the latest posts for a set of configured feeds, attaching each
  # post's ConfiguredFeed presentation metadata.
  class Fetcher
    def latest(feed_list:, page: 1, query: nil)
      return [] if feed_list.feed_ids.empty?

      posts = Post.for_feeds(feed_list.feed_ids)
      posts = posts.matching(query) if query.present?
      posts = posts.page(page, Rails.configuration.x.rss.posts_per_page).to_a

      attach_feed_config(posts, feed_list)
      posts
    end

    private
      def attach_feed_config(posts, feed_list)
        by_id = feed_list.mapped_by_id
        posts.each { |post| post.feed_config = by_id[post.feed_id] }
      end
  end
end
