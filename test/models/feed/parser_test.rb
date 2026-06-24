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

  test "returns an empty array for malformed xml" do
    assert_empty @parser.parse("this is not xml at all <<<")
  end

  test "returns an empty array for empty input" do
    assert_empty @parser.parse("")
  end
end
