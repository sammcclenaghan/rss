# frozen_string_literal: true

class Feed
  # Loads feed configuration, ensures a Feed record exists for each configured
  # URL, and exposes filtered views (all / visible / by tag / by url).
  class Provider
    def self.from_app_config(refresh_new_feeds: true)
      new(config: Config.from_app_config, refresh_new_feeds: refresh_new_feeds)
    end

    def initialize(config: Config.new, refresh_new_feeds: true)
      @config = config
      @refresh_new_feeds = refresh_new_feeds
      @configured_feeds = build_configured_feeds
    end

    def all
      touch_accessed(@configured_feeds)
      List.new(@configured_feeds)
    end

    def visible
      reject_hidden.tap { |feeds| touch_accessed(feeds) }.then { |feeds| List.new(feeds) }
    end

    def for_tag(tag)
      tag = "##{tag}" unless tag.start_with?("#")
      select { |feed| feed.tags.include?(tag) }
    end

    def for_url(url)
      get(url)&.then { |feed| List.new([ feed ]) } || List.new
    end

    def get(url)
      @configured_feeds.find { |feed| feed.url == url }&.tap { |feed| touch_accessed([ feed ]) }
    end

    private

    def select(&block)
      feeds = @configured_feeds.select(&block)
      touch_accessed(feeds)
      List.new(feeds)
    end

    def reject_hidden
      @configured_feeds.reject(&:hidden?)
    end

    def build_configured_feeds
      existing = Feed.where(url: @config.feed_urls).index_by(&:url)

      @config.feed_urls.map do |url|
        feed = existing[url] || create_feed(url)

        ConfiguredFeed.new(
          feed: feed,
          name: @config.name_for(url),
          url: url,
          color: @config.color_for(url),
          tags: @config.tags_for(url),
          hidden: @config.hidden?(url),
          proxy: @config.proxy_for(url)
        )
      end
    end

    # Creates a Feed record for a URL that wasn't in the database, and kicks
    # off a refresh so the new feed's first fetch happens automatically
    # instead of waiting for the next scheduled RefreshOutdatedFeedsJob tick.
    def create_feed(url)
      feed = Feed.create!(url: url)
      RefreshFeedJob.perform_later(feed) if @refresh_new_feeds
      feed
    end

    def touch_accessed(configured_feeds)
      ids = configured_feeds.map { |feed| feed.feed.id }
      Feed.where(id: ids).update_all(last_accessed_at: Time.current.to_i) if ids.any?
    end
  end
end
