# frozen_string_literal: true

require "rexml/document"
require "time"

module FeedParser
  module Atom
    NS = { "atom" => "http://www.w3.org/2005/Atom" }.freeze

    module_function

    def able_to_parse?(xml)
      %r{<feed\b[^>]*\sxmlns\s*=\s*["'](?:https?://www\.w3\.org/2005/Atom|http://purl\.org/atom/ns#)["']}i.match?(xml)
    end

    def parse(xml)
      document = REXML::Document.new(xml)
      root = document.root
      raise ParseError, "not an Atom feed" unless root&.name == "feed" && atom_namespace?(root)

      Feed.new(
        id: text(root, "atom:id"),
        title: text(root, "atom:title"),
        description: text(root, "atom:subtitle"),
        url: link_href(root, rel: "alternate") || link_href(root),
        feed_url: link_href(root, rel: "self"),
        updated: time(text(root, "atom:updated")),
        authors: authors(root),
        links: links(root),
        entries: REXML::XPath.match(root, "atom:entry", NS).map { |entry| parse_entry(entry) },
      )
    rescue REXML::ParseException => e
      raise ParseError, e.message
    end

    def parse_entry(node)
      Entry.new(
        id: text(node, "atom:id"),
        title: text(node, "atom:title"),
        url: link_href(node, rel: "alternate") || link_href(node),
        summary: text(node, "atom:summary"),
        content: text(node, "atom:content"),
        published: time(text(node, "atom:published")),
        updated: time(text(node, "atom:updated")),
        authors: authors(node),
        links: links(node),
      )
    end

    def atom_namespace?(root)
      ns = root.namespace
      ns == "http://www.w3.org/2005/Atom" || ns == "http://purl.org/atom/ns#"
    end

    def text(node, path)
      element = REXML::XPath.first(node, path, NS)
      value = element&.text&.strip
      value unless value&.empty?
    end

    def links(node)
      REXML::XPath.match(node, "atom:link", NS).filter_map { |element| build_link(element) }.freeze
    end

    def link_href(node, rel: nil)
      links(node).each do |link|
        next if rel && link.rel != rel

        return link.href
      end
      nil
    end

    def build_link(element)
      href = element.attributes["href"]&.strip
      return if href.nil? || href.empty?

      Link.new(
        href: href,
        rel: present_attribute(element, "rel"),
        type: present_attribute(element, "type"),
        hreflang: present_attribute(element, "hreflang"),
        title: present_attribute(element, "title"),
        length: integer_attribute(element, "length"),
      )
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

    def authors(node)
      REXML::XPath.match(node, "atom:author", NS).filter_map do |author|
        name = text(author, "atom:name")
        email = text(author, "atom:email")
        uri = text(author, "atom:uri")
        next if name.nil? && email.nil? && uri.nil?

        { name: name, email: email, uri: uri }.compact.freeze
      end.freeze
    end

    def time(value)
      Time.parse(value) if value
    rescue ArgumentError
      nil
    end
  end
end
