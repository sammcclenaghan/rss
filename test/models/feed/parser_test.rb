require "test_helper"

class Feed::ParserTest < ActiveSupport::TestCase
  setup { @parser = Feed::Parser.new }

  test "parses RSS 2.0 items into posts" do
    posts = @parser.parse(file_fixture_content("rss_feed.xml"))

    assert_equal 2, posts.size
    assert_equal "First Post", posts.first.title
    assert_equal "https://example.com/first", posts.first.url
    assert_equal "https://example.com/first", posts.first.guid
  end

  test "parses Atom entries into posts" do
    posts = @parser.parse(file_fixture_content("atom_feed.xml"))

    assert_equal 2, posts.size
    assert_equal "Atom Entry One", posts.first.title
    assert_equal "https://example.com/atom-one", posts.first.url
    assert_equal "tag:example.com,2025:atom-one", posts.first.guid
  end

  test "falls back to the link as guid when guid is missing" do
    rss = <<~XML
      <rss><channel><item>
        <title>No Guid</title>
        <link>https://example.com/no-guid</link>
        <pubDate>Tue, 10 Jun 2025 09:00:00 +0000</pubDate>
      </item></channel></rss>
    XML

    assert_equal "https://example.com/no-guid", @parser.parse(rss).first.guid
  end

  test "strips HTML and decodes entities in descriptions" do
    post = @parser.parse(file_fixture_content("rss_feed.xml")).first
    assert_equal "The first post's body.", post.description
  end

  test "skips items without a valid url" do
    titles = @parser.parse(file_fixture_content("rss_feed.xml")).map(&:title)
    assert_not_includes titles, "Invalid (no url)"
  end

  test "skips items with non-http urls" do
    rss = <<~XML
      <rss><channel><item>
        <title>FTP Post</title>
        <link>ftp://example.com/file</link>
        <guid>ftp-guid</guid>
        <pubDate>Tue, 10 Jun 2025 09:00:00 +0000</pubDate>
      </item></channel></rss>
    XML

    assert_empty @parser.parse(rss)
  end

  test "skips items without a parseable publish date" do
    rss = <<~XML
      <rss><channel><item>
        <title>Undated</title>
        <link>https://example.com/undated</link>
        <guid>undated</guid>
      </item></channel></rss>
    XML

    assert_empty @parser.parse(rss)
  end

  test "truncates long titles to 250 characters" do
    long_title = "a" * 300
    rss = <<~XML
      <rss><channel><item>
        <title>#{long_title}</title>
        <link>https://example.com/long</link>
        <guid>long</guid>
        <pubDate>Tue, 10 Jun 2025 09:00:00 +0000</pubDate>
      </item></channel></rss>
    XML

    title = @parser.parse(rss).first.title
    assert_equal 253, title.length
    assert title.end_with?("...")
  end

  test "captures content:encoded as the raw content for RSS items" do
    rss = <<~XML
      <rss version="2.0" xmlns:content="http://purl.org/rss/1.0/modules/content/">
        <channel><item>
          <title>Full</title>
          <link>https://example.com/full</link>
          <guid>full</guid>
          <pubDate>Tue, 10 Jun 2025 09:00:00 +0000</pubDate>
          <description>Short teaser.</description>
          <content:encoded><![CDATA[<p>The <b>full</b> article body.</p>]]></content:encoded>
        </item></channel>
      </rss>
    XML

    post = @parser.parse(rss).first
    assert_equal "<p>The <b>full</b> article body.</p>", post.raw_content
    assert_equal "Short teaser.", post.description
  end

  test "carries feed-provided image URLs on parsed posts" do
    rss = <<~XML
      <rss version="2.0" xmlns:media="http://search.yahoo.com/mrss/">
        <channel><item>
          <title>Image</title>
          <link>https://example.com/image</link>
          <guid>image</guid>
          <pubDate>Tue, 10 Jun 2025 09:00:00 +0000</pubDate>
          <media:thumbnail url="https://cdn.example.com/image.jpg" />
        </item></channel>
      </rss>
    XML

    post = @parser.parse(rss).first

    assert_equal "https://cdn.example.com/image.jpg", post.feed_image_url
  end

  test "captures <content> as the raw content for Atom entries" do
    post = @parser.parse(file_fixture_content("atom_feed.xml")).last
    assert_equal "Falls back to content when no summary.", post.raw_content
  end

  test "falls back to <summary> as raw content when <content> is missing" do
    post = @parser.parse(file_fixture_content("atom_feed.xml")).first
    assert_equal "The summary of entry one.", post.raw_content
  end

  test "prefers <content> over <summary> when both are present" do
    atom = <<~XML
      <?xml version="1.0" encoding="UTF-8"?>
      <feed xmlns="http://www.w3.org/2005/Atom">
        <entry>
          <title>Both</title>
          <link href="https://example.com/both"/>
          <id>tag:example.com,2025:both</id>
          <updated>2025-06-12T10:00:00Z</updated>
          <summary>Short teaser.</summary>
          <content>Full article body.</content>
        </entry>
      </feed>
    XML

    post = @parser.parse(atom).first
    assert_equal "Full article body.", post.raw_content
    assert_equal "Short teaser.", post.description
  end

  test "returns an empty array for malformed xml" do
    assert_empty @parser.parse("this is not xml at all <<<")
  end

  test "returns an empty array for empty input" do
    assert_empty @parser.parse("")
  end
end
