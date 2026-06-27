require "cgi"

class Feed
  # Parses RSS 2.0, Atom, and RSS 1.0 (RDF) feed data into unsaved Post records.
  class Parser
    MAX_TITLE = 250
    MAX_DESCRIPTION = 200
    MIN_VALID_TIMESTAMP = 1000

    # Where the full article HTML lives. Only genuine full-content elements —
    # never the summary/description, which is a teaser, not the article. After
    # remove_namespaces!, content:encoded is just <encoded>.
    RSS_CONTENT = %w[encoded].freeze
    ATOM_CONTENT = %w[content].freeze

    def parse(data)
      doc = Nokogiri::XML(data.to_s.strip)
      doc.remove_namespaces!
      items, format = locate_items(doc)
      items.filter_map { |item| build_post(item, format) }
    end

    private
      def locate_items(doc)
        if (items = doc.xpath("/rss/channel/item")).any?
          [ items, :rss ]
        elsif (items = doc.xpath("/feed/entry")).any?
          [ items, :atom ]
        else
          [ doc.xpath("//item"), :rss ]
        end
      end

      def build_post(item, format)
        attributes = format == :atom ? atom_attributes(item) : rss_attributes(item)
        return unless valid?(attributes)

        raw_content = attributes.delete(:raw_content)
        Post.new(attributes).tap { |post| post.raw_content = raw_content }
      end

      def rss_attributes(item)
        link = text(item, "link")
        {
          title: truncate(text(item, "title"), MAX_TITLE),
          description: format_description(text(item, "description")),
          raw_content: full_content(item, RSS_CONTENT),
          url: link,
          guid: text(item, "guid").presence || link,
          published_at: parse_time(text(item, "pubDate"), :rfc2822)
        }
      end

      def atom_attributes(item)
        link = item.at_xpath("link")&.then { |el| (el["href"] || el.text).to_s.strip }.to_s
        published = text(item, "published").presence || text(item, "updated")
        summary = text(item, "summary").presence
        content = text(item, "content").presence
        {
          title: truncate(decode(text(item, "title")), MAX_TITLE),
          description: format_description(summary || content),
          # Many Atom feeds (e.g. simonwillison.net) put the full article in
          # <summary> and omit <content>. Per the Atom spec, summary is allowed
          # to carry the full body, so fall back to it when <content> is absent.
          raw_content: content || summary,
          url: link,
          guid: text(item, "id").presence || link,
          published_at: parse_time(published, :iso8601)
        }
      end

      def text(item, selector)
        item.at_xpath(selector)&.text.to_s.strip
      end

      # Raw, untruncated article HTML from the first populated selector. Left
      # unsanitized here; Feed::Refresher runs it through ContentFilters.
      def full_content(item, selectors)
        selectors.filter_map { |selector| text(item, selector).presence }.first.to_s
      end

      def parse_time(string, format)
        return 0 if string.blank?
        (format == :iso8601 ? Time.iso8601(string) : Time.rfc2822(string)).to_i
      rescue ArgumentError
        0
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
