require "restricted_http/client"

class Feed
  # Fetches RSS/Atom feed data over HTTP (guarded against SSRF) and parses it
  # into unsaved Post records. The HTTP client is injectable.
  class Fetcher
    USER_AGENT = "rss-reader/1.0"
    MAX_FEED_SIZE = 10.megabytes
    VALID_OPENINGS = %w[<?xml <feed <rss].freeze

    def initialize(parser: Parser.new, client: default_client)
      @parser = parser
      @client = client
    end

    # Returns an array of unsaved Post records, or [] on any failure.
    def fetch(feed)
      response = @client.get(feed.url)
      return [] unless response&.ok?

      data = response.body.to_s.lstrip
      return [] unless looks_like_feed?(data)

      @parser.parse(data)
    end

    # Best-effort feed title for a URL, used to auto-name a newly added feed.
    # Returns nil on any HTTP/parse failure (the caller falls back to the host).
    def title(url)
      response = @client.get(url)
      return unless response&.ok?

      data = response.body.to_s.lstrip
      return unless looks_like_feed?(data)

      @parser.title(data)
    rescue StandardError
      nil
    end

    private
      def default_client
        RestrictedHTTP::Client.new(user_agent: USER_AGENT, max_body_size: MAX_FEED_SIZE)
      end

      def looks_like_feed?(data)
        VALID_OPENINGS.include?(data[0, 20].split.first)
      end
  end
end
