# frozen_string_literal: true

require "zlib"
require "base64"

class Feed
  # Parses, serializes, and URL-encodes the feeds configuration text format.
  #
  #   https://example.com/feed.xml Display_Name[#color] #tag1 #tag2
  #   -https://example.com/hidden.xml Hidden #tag    (leading "-" hides it)
  #
  # Underscores in names render as spaces; lines starting with "#" are comments.
  class Config
    Entry = Struct.new(:name, :tags, :color, :hidden, :proxy, keyword_init: true)

    BlankUrl = Class.new(StandardError)
    InvalidUrl = Class.new(StandardError)
    DuplicateUrl = Class.new(StandardError)

    NAME_COLOR = /\A(?<name>.*)\[(?<color>.*)\]\z/

    def self.from_app_config
      new.tap do |config|
        path = Rails.configuration.x.rss.config_file
        config.parse(File.read(path)) if path && File.exist?(path)
      end
    end

    # Match the original Laravel/Inertia app's wire format: feed links are
    # double-encoded in the generated href so slashes, colons, and .xml suffixes
    # remain path-safe. Rails path helpers add one escaping layer themselves, so
    # callers pass this single-encoded segment to `feed_posts_path`.
    def self.encode_feed_url(url)
      CGI.escape(url)
    end

    def self.decode_feed_url(encoded)
      CGI.unescape(encoded.to_s)
    end

    def initialize
      @entries = {}
    end

    def feed_urls = @entries.keys
    def name_for(url) = @entries[url]&.name.to_s
    def tags_for(url) = @entries[url]&.tags || []
    def color_for(url) = @entries[url]&.color.to_s
    def hidden?(url) = @entries[url]&.hidden || false
    def proxy_for(url) = @entries[url]&.proxy.to_s
    def include?(url) = @entries.key?(url)

    # The on-disk path the config is read from and written back to. Set via
    # RSS_CONFIG_FILE (see config/initializers/rss.rb); volume-backed in
    # production so feed edits survive redeploys.
    def self.config_path = Rails.configuration.x.rss.config_file

    def add_feed(url: nil, name: nil, tag: nil, color: "", hidden: false, proxy: "")
      url = normalized_url(url)
      raise DuplicateUrl if include?(url)

      name = normalized_name(name, url)
      prepend(url, name: name, tags: tags_from_group(tag), color: color.to_s.strip,
                   hidden: ActiveModel::Type::Boolean.new.cast(hidden), proxy: normalize_proxy(proxy))
      save_and_refresh
      name
    end

    def update_feed(feed, name: nil, tag: nil, color: "", hidden: false, proxy: "", **)
      name = name.to_s.strip.presence || feed.url
      add(feed.url, name: name, tags: tags_from_group(tag), color: color.to_s.strip,
                    hidden: ActiveModel::Type::Boolean.new.cast(hidden), proxy: normalize_proxy(proxy))
      save_and_refresh
      name
    end

    def remove_feed(feed)
      remove(feed.url)
      save!
      feed.destroy
    end

    def import_opml(contents)
      Feed::Opml.import(contents, into: self).tap do |count|
        save_and_refresh if count.positive?
      end
    end

    def add(url, name:, tags: [], color: "", hidden: false, proxy: "")
      @entries[url] = Entry.new(name: name, tags: tags, color: color, hidden: hidden, proxy: proxy)
      self
    end

    # Adds an entry to the front of the list (newest feeds surface first in the
    # sidebar's Default folder before any tag ordering kicks in).
    def prepend(url, name:, tags: [], color: "", hidden: false, proxy: "")
      entry = Entry.new(name: name, tags: tags, color: color, hidden: hidden, proxy: proxy)
      @entries = { url => entry }.merge(@entries.except(url))
      self
    end

    def remove(url)
      @entries.delete(url)
      self
    end

    # Atomically writes the current entries back to disk (temp file + rename so
    # a crash mid-write can't truncate the live config). Note: comments and
    # blank lines from the source file are not preserved — grouping is by tag.
    def save!(path = self.class.config_path)
      tmp = "#{path}.#{Process.pid}.tmp"
      File.write(tmp, "#{self}\n")
      File.rename(tmp, path)
      self
    end

    def parse(string)
      string.each_line do |line|
        parse_line(line.strip)
      end
      self
    end

    def to_s
      @entries.map { |url, entry| serialize_entry(url, entry) }.join("\n")
    end

    # Returns the shorter of a URL-encoded or zlib-compressed representation,
    # prefixed with "t" or "c" respectively.
    def encode_for_url
      text = to_s
      url_encoded = "t#{CGI.escape(text)}"
      compressed = "c#{Base64.urlsafe_encode64(Zlib::Deflate.deflate(text), padding: false)}"
      [ url_encoded, compressed ].min_by(&:bytesize)
    end

    def decode_from_url(encoded)
      return self if encoded.blank?

      text =
        case encoded[0]
        when "t" then CGI.unescape(encoded[1..])
        when "c" then Zlib::Inflate.inflate(Base64.urlsafe_decode64(encoded[1..]))
        else return self
        end

      parse(text)
    end

    private

    def normalized_url(url)
      url.to_s.strip.tap do |normalized|
        raise BlankUrl if normalized.blank?
        raise InvalidUrl unless normalized.match?(%r{\Ahttps?://}i)
      end
    end

    def normalized_name(name, url)
      name.to_s.strip.presence || Feed.discover_name_for(url)
    end

    # A single group field becomes one "#tag"; blank means the Default folder.
    def tags_from_group(group)
      tag = group.to_s.strip.delete_prefix("#").downcase.gsub(/\s+/, "-")
      tag.blank? ? [] : [ "##{tag}" ]
    end

    # An optional library EZProxy host for routing this feed's article links
    # through institutional access. Accepts a bare host or a pasted URL; we keep
    # just the host (no scheme, no path), and strip any leading "login." so the
    # host-mangled article URL resolves rather than hitting the login endpoint.
    def normalize_proxy(proxy)
      proxy.to_s.strip.sub(%r{\Ahttps?://}i, "").split("/").first.to_s.delete_prefix("login.")
    end

    # Rebuilds the provider so newly-configured feeds get a DB record and an
    # initial refresh enqueued.
    def save_and_refresh
      save!
      Feed::Provider.from_app_config
    end

    def parse_line(line)
      return if line.blank? || line.start_with?("#")

      hidden = line.start_with?("-")
      line = line.delete_prefix("-").strip if hidden

      url, raw_name, *rest = line.split(/\s+/)
      return unless raw_name && url&.match?(%r{\Ahttps?://})

      name, color = split_name_and_color(raw_name)
      tags = rest.select { |part| part.start_with?("#") }
      proxy = rest.find { |part| part.start_with?("proxy=") }&.delete_prefix("proxy=").to_s

      add(url, name: name.tr("_", " "), tags: tags, color: color, hidden: hidden, proxy: proxy)
    end

    def split_name_and_color(raw_name)
      if (match = raw_name.match(NAME_COLOR))
        [ match[:name], match[:color] ]
      else
        [ raw_name, "" ]
      end
    end

    def serialize_entry(url, entry)
      line = +"#{url} #{entry.name.tr(' ', '_')}"
      line << "[#{entry.color}]" if entry.color.present?
      entry.tags.each { |tag| line << " #{tag}" }
      line << " proxy=#{entry.proxy}" if entry.proxy.present?
      entry.hidden ? "-#{line}" : line
    end
  end
end
