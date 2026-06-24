class Feed
  # Refreshes a feed: fetches its current posts, upserts them, optionally
  # enqueues thumbnail fetches for new posts, and stamps the feed as fetched.
  #
  # The fetcher and thumbnail behaviour are injectable so this can be driven
  # with a fake fetcher in tests.
  class Refresher
    def initialize(fetcher: Fetcher.new, load_thumbnails: Rails.configuration.x.rss.load_post_thumbnails)
      @fetcher = fetcher
      @load_thumbnails = load_thumbnails
    end

    def refresh(feed)
      @fetcher.fetch(feed).each do |incoming|
        created = upsert(feed, incoming)
        FetchPostThumbnailJob.perform_later(created) if created && @load_thumbnails
      end

      feed.mark_fetched
    end

    private
      # Returns the post if it was newly created, otherwise nil.
      def upsert(feed, incoming)
        post = feed.posts.find_or_initialize_by(guid: incoming.guid)
        created = post.new_record?

        post.update!(
          title: incoming.title,
          description: incoming.description,
          url: incoming.url,
          published_at: incoming.published_at
        )

        post if created
      end
  end
end
