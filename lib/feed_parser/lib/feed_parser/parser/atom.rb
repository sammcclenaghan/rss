# frozen_string_literal: true

require 'nokogiri'
require 'time'

module FeedParser
  module Parser
    module Atom
      ATOM_NAMESPACES = ['http://www.w3.org/2005/Atom', 'http://purl.org/atom/ns#'].freeze

      module_function

      def able_to_parse?(xml)
        %r{<feed\b[^>]*\sxmlns\s*=\s*["'](?:https?://www\.w3\.org/2005/Atom|http://purl\.org/atom/ns#)["']}i.match?(xml)
      end

      def parse(xml)
        document = Nokogiri::XML(xml) { |config| config.recover.nonet }
        root = document.root
        raise ParseError, 'not an Atom feed' unless root&.name == 'feed' && atom_namespace?(root)

        feed_authors = people(root, 'author')
        feed_links = links(root)

        Feed.new(
          id: text(root, 'id'),
          title: text(root, 'title'),
          description: text(root, 'subtitle'),
          url: href_for(feed_links, rel: 'alternate') || href_for(feed_links),
          feed_url: href_for(feed_links, rel: 'self'),
          image: feed_image(root),
          updated: time(text(root, 'updated')),
          authors: feed_authors,
          categories: categories(root),
          links: feed_links,
          entries: children(root, 'entry').map { |entry| parse_entry(entry, inherited_authors: feed_authors) }.freeze
        )
      rescue Nokogiri::XML::SyntaxError => e
        raise ParseError, e.message
      end

      def parse_entry(node, inherited_authors: EMPTY_ARRAY)
        entry_authors = people(node, 'author')
        entry_links = links(node)
        summary = text(node, 'summary')

        Entry.new(
          id: text(node, 'id'),
          title: text(node, 'title'),
          url: href_for(entry_links, rel: 'alternate') || href_for(entry_links),
          summary: summary,
          content: text(node, 'content') || summary,
          image: entry_image(node),
          published: time(text(node, 'published')),
          updated: time(text(node, 'updated')),
          authors: entry_authors.empty? ? inherited_authors : entry_authors,
          categories: categories(node),
          links: entry_links
        )
      end

      def atom_namespace?(root)
        ATOM_NAMESPACES.include?(root.namespace&.href)
      end

      def children(node, name)
        node.element_children.select { |child| child.name == name }
      end

      def child(node, name)
        node.element_children.find { |child| child.name == name }
      end

      def text(node, name)
        value = child(node, name)&.text&.strip
        value unless value.nil? || value.empty?
      end

      def links(node)
        children(node, 'link').filter_map { |element| build_link(element) }.freeze
      end

      def href_for(links, rel: nil)
        links.each do |link|
          next if rel && link.rel != rel

          return link.href
        end
        nil
      end

      def feed_image(node)
        text(node, 'logo') || text(node, 'icon')
      end

      def entry_image(node)
        attribute(child_with_prefix(node, 'media', 'thumbnail'), 'url') ||
          attribute(child_with_prefix(node, 'media', 'content'), 'url')
      end

      def child_with_prefix(node, prefix, name)
        node.element_children.find { |child| child.namespace&.prefix == prefix && child.name == name }
      end

      def build_link(element)
        href = element['href']&.strip
        return if href.nil? || href.empty?

        Link.new(
          href: href,
          rel: present_attribute(element, 'rel'),
          type: present_attribute(element, 'type'),
          hreflang: present_attribute(element, 'hreflang'),
          title: present_attribute(element, 'title'),
          length: integer_attribute(element, 'length')
        )
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

      def people(node, element_name)
        children(node, element_name).filter_map do |person|
          name = text(person, 'name')
          email = text(person, 'email')
          uri = text(person, 'uri')
          next if name.nil? && email.nil? && uri.nil?

          Person.new(name: name, email: email, uri: uri)
        end.freeze
      end

      def categories(node)
        children(node, 'category').filter_map do |element|
          term = present_attribute(element, 'term')
          next unless term

          Category.new(
            term: term,
            scheme: present_attribute(element, 'scheme'),
            label: present_attribute(element, 'label')
          )
        end.freeze
      end

      def time(value)
        Time.parse(value) if value
      rescue ArgumentError
        nil
      end
    end
  end
end
