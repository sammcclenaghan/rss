# frozen_string_literal: true

require "rexml/document"
require "time"

module FeedParser
  module Atom
    NS = { "atom" => "http://www.w3.org/2005/Atom" }.freeze

    module_function

    def parse(xml)
      document = REXML::Document.new(xml)
      root = document.root
      raise ParseError, "not an Atom feed" unless root&.name == "feed" && atom_namespace?(root)

      Feed.new(
        id: text(root, "atom:id"),
        title: text(root, "atom:title"),
        description: text(root, "atom:subtitle"),
        url: link(root, rel: "alternate") || link(root),
        feed_url: link(root, rel: "self"),
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
        url: link(node, rel: "alternate") || link(node),
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
      REXML::XPath.match(node, "atom:link", NS).filter_map do |element|
        href = element.attributes["href"]&.strip
        href unless href.empty?
      end.freeze
    end

    def link(node, rel: nil)
      REXML::XPath.match(node, "atom:link", NS).each do |element|
        next if rel && element.attributes["rel"] != rel

        href = element.attributes["href"]&.strip
        return href unless href.nil? || href.empty?
      end
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
