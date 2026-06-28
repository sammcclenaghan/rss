class Feed
  # Refreshes a feed: fetches its current posts, upserts them, optionally
  # enqueues thumbnail fetches for new posts, and stamps the feed as fetched.
  #
  # The fetcher and thumbnail behaviour are injectable so this can be driven
  # with a fake fetcher in tests.
  class Refresher
    def initialize(fetcher: Fetcher.new,
                   load_thumbnails: Rails.configuration.x.rss.load_post_thumbnails)
      @fetcher = fetcher
      @load_thumbnails = load_thumbnails
    end

    def refresh(feed)
      incoming_posts = @fetcher.fetch(feed)
      Rails.logger.info("Feed refresh started feed_id=#{feed.id} url=#{feed.url} incoming=#{incoming_posts.size}")

      created_count = 0

      incoming_posts.each do |incoming|
        post, created = upsert(feed, incoming)
        created_count += 1 if created
        enqueue_thumbnail(post, incoming) if created && @load_thumbnails
      end

      feed.mark_fetched
      Rails.logger.info(
        "Feed refresh finished feed_id=#{feed.id} url=#{feed.url} " \
        "incoming=#{incoming_posts.size} created=#{created_count}"
      )
    end

    private
      # Returns [post, created?] where created? is true for new records.
      def upsert(feed, incoming)
        post = feed.posts.find_or_initialize_by(guid: incoming.guid)
        created = post.new_record?

        post.update!(
          title: incoming.title,
          description: incoming.description,
          url: incoming.url,
          published_at: incoming.published_at
        )

        [ post, created ]
      end

      def enqueue_thumbnail(post, incoming)
        FetchPostThumbnailJob.perform_later(post, incoming.feed_image_url.presence)
      end
  end
end
