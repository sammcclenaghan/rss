require "rexml/document"

class Feed
  # Imports and exports the feed list as OPML, the interchange format every RSS
  # reader speaks. Groups map to nested category outlines (one level deep, by
  # the feed's first tag); feeds without a tag sit at the body root.
  module Opml
    module_function

    # Serializes a Feed::Config to an OPML 2.0 document string.
    def export(config)
      doc = REXML::Document.new
      doc << REXML::XMLDecl.new("1.0", "UTF-8")

      opml = doc.add_element("opml", "version" => "2.0")
      opml.add_element("head").add_element("title").text = "RSS feeds"
      body = opml.add_element("body")

      grouped(config).each do |group, entries|
        container =
          if group
            body.add_element("outline", "text" => group, "title" => group)
          else
            body
          end

        entries.each { |entry| container.add_element("outline", feed_attributes(entry)) }
      end

      String.new.tap { |out| doc.write(output: out, indent: 2) }
    end

    # Parses an OPML string and adds every feed outline into the given
    # Feed::Config (existing entries with the same URL are overwritten). The
    # enclosing category outline's text becomes the feed's tag. Returns the
    # number of feeds imported.
    def import(xml, into:)
      doc = REXML::Document.new(xml)
      count = 0

      doc.each_element("//outline") do |el|
        url = el.attribute("xmlUrl")&.value.to_s.strip
        next if url.blank? || !url.match?(%r{\Ahttps?://}i)

        name = (el.attribute("text") || el.attribute("title"))&.value.to_s.strip
        name = url if name.blank?
        into.add(url, name: name, tags: tags_from_parent(el))
        count += 1
      end

      count
    rescue REXML::ParseException
      0
    end

    # --- helpers -------------------------------------------------------------

    def grouped(config)
      config.feed_urls.group_by do |url|
        tag = config.tags_for(url).first.to_s.delete_prefix("#")
        tag.presence
      end.transform_values { |urls| urls.map { |url| entry_for(config, url) } }
    end

    def entry_for(config, url)
      { url: url, name: config.name_for(url), color: config.color_for(url) }
    end

    def feed_attributes(entry)
      attrs = { "type" => "rss", "text" => entry[:name], "title" => entry[:name], "xmlUrl" => entry[:url] }
      attrs["text"] = entry[:url] if entry[:name].blank?
      attrs["title"] = attrs["text"]
      attrs
    end

    def tags_from_parent(element)
      parent = element.parent
      return [] unless parent&.name == "outline"

      # A category outline has no xmlUrl of its own.
      return [] if parent.attribute("xmlUrl")

      tag = (parent.attribute("text") || parent.attribute("title"))&.value.to_s.strip
      tag.blank? ? [] : [ "##{tag}" ]
    end
  end
end
