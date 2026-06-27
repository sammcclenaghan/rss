# frozen_string_literal: true

require "rexml/document"
require "time"

module FeedParser
  module Parser
    module RSS
      module_function

      def able_to_parse?(xml)
        %r{<rss\b|<rdf:RDF\b}i.match?(xml)
      end

      def parse(xml)
        document = REXML::Document.new(xml)
        channel = REXML::XPath.first(document, "/rss/channel")
        raise ParseError, "not an RSS feed" unless channel

        Feed.new(
          title: text(channel, "title"),
          description: text(channel, "description"),
          url: text(channel, "link"),
          feed_url: atom_self_link(channel),
          updated: time(text(channel, "lastBuildDate") || text(channel, "pubDate")),
          authors: people_from_text(text(channel, "managingEditor") || text(channel, "webMaster")),
          categories: categories(channel),
          links: links(channel),
          entries: REXML::XPath.match(channel, "item").map { |item| parse_item(item) }.freeze,
        )
      rescue REXML::ParseException => e
        raise ParseError, e.message
      end

      def parse_item(node)
        Entry.new(
          id: text(node, "guid") || text(node, "link"),
          title: text(node, "title"),
          url: text(node, "link"),
          summary: text(node, "description"),
          content: text(node, "content:encoded"),
          published: time(text(node, "pubDate")),
          authors: people_from_text(text(node, "author")),
          categories: categories(node),
          links: links(node),
        )
      end

      def text(node, path)
        element = REXML::XPath.first(node, path)
        value = element&.text&.strip
        value unless value.nil? || value.empty?
      end

      def atom_self_link(node)
        REXML::XPath.match(node, "atom:link", { "atom" => "http://www.w3.org/2005/Atom" }).each do |element|
          next unless element.attributes["rel"] == "self"

          href = element.attributes["href"]&.strip
          return href unless href.nil? || href.empty?
        end
        nil
      end

      def links(node)
        hrefs = []
        link = text(node, "link")
        hrefs << Link.new(href: link, rel: "alternate") if link

        enclosure = REXML::XPath.first(node, "enclosure")
        if enclosure && (href = enclosure.attributes["url"]&.strip) && !href.empty?
          hrefs << Link.new(
            href: href,
            rel: "enclosure",
            type: present_attribute(enclosure, "type"),
            length: integer_attribute(enclosure, "length"),
          )
        end

        hrefs.freeze
      end

      def categories(node)
        REXML::XPath.match(node, "category").filter_map do |element|
          term = element.text&.strip
          next if term.nil? || term.empty?

          Category.new(term: term, scheme: present_attribute(element, "domain"))
        end.freeze
      end

      def people_from_text(value)
        return EMPTY_ARRAY unless value

        [Person.new(email: value)].freeze
      end

      def present_attribute(element, name)
        value = element.attributes[name]&.strip
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
