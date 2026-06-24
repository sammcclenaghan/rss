require "test_helper"

class Feed::ConfigTest < ActiveSupport::TestCase
  setup { @config = Feed::Config.new }

  test "parses a feed line with name, color, and tags" do
    @config.parse("https://example.com/feed.xml Cool_Blog[#ff0000] #tech #ruby")

    url = "https://example.com/feed.xml"
    assert_equal [ url ], @config.feed_urls
    assert_equal "Cool Blog", @config.name_for(url)
    assert_equal "#ff0000", @config.color_for(url)
    assert_equal %w[#tech #ruby], @config.tags_for(url)
    assert_not @config.hidden?(url)
  end

  test "treats a leading dash as a hidden feed" do
    @config.parse("-https://example.com/feed.xml Secret")
    assert @config.hidden?("https://example.com/feed.xml")
  end

  test "ignores comments, blank lines, and non-http urls" do
    @config.parse(<<~CONFIG)
      # a comment

      ftp://example.com/feed.xml Nope
      https://example.com/ok.xml Yep
    CONFIG

    assert_equal [ "https://example.com/ok.xml" ], @config.feed_urls
  end

  test "round-trips through to_s and parse" do
    source = "https://example.com/feed.xml My_Blog[#abc] #tag"
    reparsed = Feed::Config.new.parse(@config.parse(source).to_s)

    assert_equal @config.feed_urls, reparsed.feed_urls
    assert_equal "My Blog", reparsed.name_for("https://example.com/feed.xml")
    assert_equal %w[#tag], reparsed.tags_for("https://example.com/feed.xml")
  end

  test "round-trips through url encoding" do
    @config.parse("https://example.com/feed.xml Blog[#fff] #news")
    decoded = Feed::Config.new.decode_from_url(@config.encode_for_url)

    assert_equal @config.feed_urls, decoded.feed_urls
    assert_equal @config.to_s, decoded.to_s
  end

  test "encode_for_url chooses the most compact representation" do
    @config.parse("https://example.com/feed.xml Blog")
    assert_includes %w[t c], @config.encode_for_url[0]
  end

  test "decode_from_url is a no-op for blank input" do
    assert_empty Feed::Config.new.decode_from_url("").feed_urls
  end

  test "from_app_config loads the configured feeds file" do
    Tempfile.create([ "feeds", ".txt" ]) do |file|
      file.write("https://example.com/from-file.xml FromFile #x")
      file.flush

      with_config_file(file.path) do
        config = Feed::Config.from_app_config
        assert_equal [ "https://example.com/from-file.xml" ], config.feed_urls
      end
    end
  end
end
