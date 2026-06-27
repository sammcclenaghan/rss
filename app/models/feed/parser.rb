require "cgi"
require_relative "../../../lib/feed_parser/lib/feed_parser"

class Feed
  # Adapts normalized FeedParser output into unsaved Post records.
  class Parser
    MAX_TITLE = 250
    MAX_DESCRIPTION = 200
    MIN_VALID_TIMESTAMP = 1000

    def parse(data)
      feed = FeedParser.parse(data.to_s.strip)
      feed.entries.filter_map { |entry| build_post(entry) }
    rescue FeedParser::ParseError
      []
    end

    private
      def build_post(entry)
        attributes = post_attributes(entry)
        return unless valid?(attributes)

        raw_content = attributes.delete(:raw_content)
        feed_image_url = attributes.delete(:feed_image_url)
        Post.new(attributes).tap do |post|
          post.raw_content = raw_content
          post.feed_image_url = feed_image_url
        end
      end

      def post_attributes(entry)
        published_at = timestamp(entry.published || entry.updated)
        url = entry.url.to_s

        {
          title: truncate(decode(entry.title), MAX_TITLE),
          description: format_description(entry.summary || entry.content),
          raw_content: entry.content.to_s,
          feed_image_url: entry.image,
          url: url,
          guid: entry.id.to_s.empty? ? url : entry.id,
          published_at: published_at,
        }
      end

      def timestamp(time)
        time&.to_i || 0
      end

      def format_description(html)
        ContentFilters::TextSummary.apply(html, length: MAX_DESCRIPTION)
      end

      def decode(string)
        CGI.unescapeHTML(string.to_s)
      end

      def truncate(string, max)
        string = string.to_s.strip
        string.length > max ? "#{string[0, max]}..." : string
      end

      def valid?(attributes)
        attributes[:title].present? &&
          attributes[:guid].present? &&
          attributes[:url].to_s.match?(%r{\Ahttps?://}) &&
          attributes[:published_at] > MIN_VALID_TIMESTAMP
      end
  end
end
