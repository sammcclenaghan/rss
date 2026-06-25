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
      @fetcher.fetch(feed).each do |incoming|
        post, created = upsert(feed, incoming)
        save_content(post, incoming) if @load_content
        FetchPostThumbnailJob.perform_later(post) if created && @load_thumbnails
        ExtractPostContentJob.perform_later(post) if created && @extract_content && post.content.nil?
      end

      feed.mark_fetched
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

      # Sanitizes the feed-provided article HTML and stores it as feed content.
      # Runs for both new and existing posts so a re-refresh backfills content
      # for the first time; Post::Content.capture guards against clobbering a
      # fuller body (e.g. a previously extracted article).
      def save_content(post, incoming)
        return if incoming.raw_content.blank?

        body = ContentFilters::ArticleContent.apply(incoming.raw_content, base_url: post.url)
        Post::Content.capture(post, body, source: Post::Content::FEED)
      end
  end
end
