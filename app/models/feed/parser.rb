require "cgi"

class Feed
  # Parses RSS 2.0, Atom, and RSS 1.0 (RDF) feed data into unsaved Post records.
  class Parser
    MAX_TITLE = 250
    MAX_DESCRIPTION = 200
    MIN_VALID_TIMESTAMP = 1000

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

        Post.new(attributes)
      end

      def rss_attributes(item)
        link = text(item, "link")
        {
          title: truncate(text(item, "title"), MAX_TITLE),
          description: format_description(text(item, "description")),
          url: link,
          guid: text(item, "guid").presence || link,
          published_at: parse_time(text(item, "pubDate"), :rfc2822)
        }
      end

      def atom_attributes(item)
        link = item.at_xpath("link")&.then { |el| (el["href"] || el.text).to_s.strip }.to_s
        published = text(item, "published").presence || text(item, "updated")
        {
          title: truncate(decode(text(item, "title")), MAX_TITLE),
          description: format_description(text(item, "summary").presence || text(item, "content")),
          url: link,
          guid: text(item, "id").presence || link,
          published_at: parse_time(published, :iso8601)
        }
      end

      def text(item, selector)
        item.at_xpath(selector)&.text.to_s.strip
      end

      def parse_time(string, format)
        return 0 if string.blank?
        (format == :iso8601 ? Time.iso8601(string) : Time.rfc2822(string)).to_i
      rescue ArgumentError
        0
      end

      def format_description(html)
        plain = ActionController::Base.helpers.strip_tags(decode(html))
        truncate(plain.gsub(/\s+/, " ").strip, MAX_DESCRIPTION)
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
