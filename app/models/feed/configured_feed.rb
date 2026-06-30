# frozen_string_literal: true

class Feed
  # Wraps a Feed record together with its configured presentation metadata
  # (name, color, tags, visibility) and transient reloading state.
  class ConfiguredFeed
    attr_reader :feed, :name, :url, :color, :tags, :hidden, :proxy
    attr_accessor :reloading

    def initialize(feed:, name:, url:, color: "", tags: [], hidden: false, proxy: "")
      @feed = feed
      @name = name
      @url = url
      @color = color
      @tags = tags
      @hidden = hidden
      @proxy = proxy
      @reloading = false
    end

    def hidden? = hidden
    def reloading? = reloading
    def encoded_url = Feed::Config.encode_feed_url(url)

    def outdated?
      feed.outdated?
    end

    def start_reloading
      RefreshFeedJob.perform_later(feed)
      self.reloading = true
    end

    def as_json(*)
      {
        name: name,
        url: url,
        color: color,
        tags: tags,
        hidden: hidden,
        reloading: reloading,
        outdated: outdated?
      }
    end
  end
end
