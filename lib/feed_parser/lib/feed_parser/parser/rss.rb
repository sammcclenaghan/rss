# frozen_string_literal: true

require "nokogiri"
require "time"

module FeedParser
  module Parser
    module RSS
      ATOM_NAMESPACE = "http://www.w3.org/2005/Atom"

      module_function

      def able_to_parse?(xml)
        /<rss\b|<rdf:RDF\b/i.match?(xml)
      end

      def parse(xml)
        document = Nokogiri::XML(xml) { |config| config.recover.nonet }
        channel = rss_channel(document.root)
        raise ParseError, "not an RSS feed" unless channel

        channel_link = text(channel, "link")
        channel_authors = authors(channel, channel: true)

        Feed.new(
          title: text(channel, "title"),
          description: text(channel, "description"),
          url: channel_link,
          feed_url: atom_self_link(channel),
          image: feed_image(channel),
          updated: time(text(channel, "lastBuildDate") || text(channel, "pubDate")),
          authors: channel_authors,
          categories: categories(channel),
          links: links(channel, alternate_href: channel_link),
          entries: children(channel, "item").map { |item| parse_item(item, inherited_authors: channel_authors) }.freeze
        )
      rescue Nokogiri::XML::SyntaxError => e
        raise ParseError, e.message
      end

      def parse_item(node, inherited_authors: EMPTY_ARRAY)
        item_link = text(node, "link")
        item_authors = authors(node)

        Entry.new(
          id: text(node, "guid") || item_link,
          title: text(node, "title"),
          url: item_link,
          summary: text(node, "description"),
          content: full_content(node),
          image: entry_image(node),
          published: time(text(node, "pubDate")),
          authors: item_authors.empty? ? inherited_authors : item_authors,
          categories: categories(node),
          links: links(node, alternate_href: item_link)
        )
      end

      def rss_channel(root)
        return unless root&.name == "rss"

        child(root, "channel")
      end

      def children(node, name)
        node.element_children.select { |element| matches_name?(element, name) }
      end

      def child(node, name)
        node.element_children.find { |element| matches_name?(element, name) }
      end

      def matches_name?(element, name)
        if name.include?(":")
          prefix, local_name = name.split(":", 2)
          element.namespace&.prefix == prefix && element.name == local_name
        else
          element.namespace.nil? && element.name == name
        end
      end

      def text(node, name)
        value = child(node, name)&.text&.strip
        value unless value.nil? || value.empty?
      end

      def full_content(node)
        text(node, "content:encoded") || text(node, "a10:content")
      end

      def feed_image(node)
        image = child(node, "image")
        (image && text(image, "url")) || attribute(child(node, "itunes:image"), "href")
      end

      def entry_image(node)
        attribute(child(node, "media:thumbnail"), "url") ||
          attribute(child(node, "media:content"), "url") ||
          image_enclosure(node)
      end

      def image_enclosure(node)
        enclosure = child(node, "enclosure")
        return unless enclosure&.[]("type")&.start_with?("image/")

        attribute(enclosure, "url")
      end

      def atom_self_link(node)
        node.element_children.each do |element|
          next unless element.name == "link" && element.namespace&.href == ATOM_NAMESPACE
          next unless element["rel"] == "self"

          href = element["href"]&.strip
          return href unless href.nil? || href.empty?
        end
        nil
      end

      def links(node, alternate_href: nil)
        hrefs = []
        hrefs << Link.new(href: alternate_href, rel: "alternate") if alternate_href

        if (enclosure = child(node, "enclosure"))
          href = enclosure["url"]&.strip
          if href && !href.empty?
            hrefs << Link.new(
              href: href,
              rel: "enclosure",
              type: present_attribute(enclosure, "type"),
              length: integer_attribute(enclosure, "length")
            )
          end
        end

        hrefs.freeze
      end

      def categories(node)
        children(node, "category").filter_map do |element|
          term = element.text&.strip
          next if term.nil? || term.empty?

          Category.new(term: term, scheme: present_attribute(element, "domain"))
        end.freeze
      end

      def authors(node, channel: false)
        people = []
        people << person_from_rss_author(text(node, "author"))
        people << person_from_name(text(node, "dc:creator"))
        people << person_from_name(text(node, "itunes:author"))

        if channel
          people << person_from_rss_author(text(node, "managingEditor"))
          people << person_from_rss_author(text(node, "webMaster"))
        end

        people.compact.uniq.freeze
      end

      def person_from_name(value)
        return unless value

        Person.new(name: value)
      end

      def person_from_rss_author(value)
        return unless value

        case value
        when /\A(.+?)\s*<([^<>\s]+@[^<>\s]+)>\z/
          Person.new(name: Regexp.last_match(1).strip, email: Regexp.last_match(2).strip)
        when /\A([^()<>\s]+@[^()<>\s]+)\s*\((.+)\)\z/
          Person.new(name: Regexp.last_match(2).strip, email: Regexp.last_match(1).strip)
        when /@/
          Person.new(email: value)
        else
          Person.new(name: value)
        end
      end

      def present_attribute(element, name)
        attribute(element, name)
      end

      def attribute(element, name)
        value = element&.[](name)&.strip
        value unless value.nil? || value.empty?
      end

      def integer_attribute(element, name)
        value = present_attribute(element, name)
        Integer(value) if value
      rescue ArgumentError
        nil
      end

      def time(value)
        Time.parse(value) if value
      rescue ArgumentError
        nil
      end
    end
  end
end
