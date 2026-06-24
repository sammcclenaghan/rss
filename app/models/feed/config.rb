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
    Entry = Struct.new(:name, :tags, :color, :hidden, keyword_init: true)

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

    def add(url, name:, tags: [], color: "", hidden: false)
      @entries[url] = Entry.new(name: name, tags: tags, color: color, hidden: hidden)
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
      url_encoded = "t" + CGI.escape(text)
      compressed = "c" + Base64.urlsafe_encode64(Zlib::Deflate.deflate(text), padding: false)
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
      def parse_line(line)
        return if line.blank? || line.start_with?("#")

        hidden = line.start_with?("-")
        line = line.delete_prefix("-").strip if hidden

        url, raw_name, *rest = line.split(/\s+/)
        return unless raw_name && url&.match?(%r{\Ahttps?://})

        name, color = split_name_and_color(raw_name)
        tags = rest.select { |part| part.start_with?("#") }

        add(url, name: name.tr("_", " "), tags: tags, color: color, hidden: hidden)
      end

      def split_name_and_color(raw_name)
        if (match = raw_name.match(NAME_COLOR))
          [ match[:name], match[:color] ]
        else
          [ raw_name, "" ]
        end
      end

      def serialize_entry(url, entry)
        line = +"#{url} #{entry.name.tr(" ", "_")}"
        line << "[#{entry.color}]" if entry.color.present?
        entry.tags.each { |tag| line << " #{tag}" }
        entry.hidden ? "-#{line}" : line
      end
  end
end
