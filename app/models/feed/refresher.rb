class Feed
  # Refreshes a feed: fetches its current posts, upserts them, optionally
  # enqueues thumbnail fetches for new posts, and stamps the feed as fetched.
  #
  # The fetcher and thumbnail behaviour are injectable so this can be driven
  # with a fake fetcher in tests.
  class Refresher
    def initialize(fetcher: Fetcher.new,
                   load_thumbnails: Rails.configuration.x.rss.load_post_thumbnails,
                   load_content: Rails.configuration.x.rss.load_post_content,
                   extract_content: Rails.configuration.x.rss.extract_url.present?)
      @fetcher = fetcher
      @load_thumbnails = load_thumbnails
      @load_content = load_content
      @extract_content = extract_content
    end

    def refresh(feed)
      incoming_posts = @fetcher.fetch(feed)
      Rails.logger.info("Feed refresh started feed_id=#{feed.id} url=#{feed.url} incoming=#{incoming_posts.size}")

      created_count = 0
      content_count = 0
      extraction_count = 0

      incoming_posts.each do |incoming|
        post, created = upsert(feed, incoming)
        created_count += 1 if created
        content_count += 1 if @load_content && save_content(post, incoming)
        enqueue_thumbnail(post, incoming) if created && @load_thumbnails
        if created && @extract_content && post.content.nil?
          ExtractPostContentJob.perform_later(post)
          extraction_count += 1
        end
      end

      feed.mark_fetched
      Rails.logger.info(
        "Feed refresh finished feed_id=#{feed.id} url=#{feed.url} " \
        "incoming=#{incoming_posts.size} created=#{created_count} " \
        "content_saved=#{content_count} extraction_enqueued=#{extraction_count}"
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

      # Sanitizes the feed-provided article HTML and stores it as feed content.
      # Runs for both new and existing posts so a re-refresh backfills content
      # for the first time; Post::Content.capture guards against clobbering a
      # fuller body (e.g. a previously extracted article).
      def save_content(post, incoming)
        return false if incoming.raw_content.blank?

        body = ContentFilters::ArticleContent.apply(incoming.raw_content, base_url: post.url)
        before = post.content&.id
        Post::Content.capture(post, body, source: Post::Content::FEED)
        saved = post.reload.content&.id != before || post.content&.source == Post::Content::FEED
        Rails.logger.info("Feed content saved post_id=#{post.id} feed_id=#{post.feed_id} bytes=#{body.to_s.bytesize}") if saved
        saved
      end
  end
end
