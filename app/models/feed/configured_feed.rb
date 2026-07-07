# frozen_string_literal: true

class Feed
  # Wraps a Feed record together with its configured presentation metadata
  # (name, color, tags, visibility).
  class ConfiguredFeed
    attr_reader :feed, :name, :url, :color, :tags, :hidden, :proxy

    def initialize(feed:, name:, url:, color: "", tags: [], hidden: false, proxy: "")
      @feed = feed
      @name = name
      @url = url
      @color = color
      @tags = tags
      @hidden = hidden
      @proxy = proxy
    end

    def hidden? = hidden
    def encoded_url = Feed::Config.encode_feed_url(url)

    def outdated?
      feed.outdated?
    end

    def as_json(*)
      {
        name: name,
        url: url,
        color: color,
        tags: tags,
        hidden: hidden,
        outdated: outdated?
      }
    end
  end
end
