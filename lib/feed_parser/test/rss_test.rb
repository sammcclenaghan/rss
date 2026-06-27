# frozen_string_literal: true

require "test_helper"

class RSSTest < Minitest::Test
  SAMPLE = <<~XML
    <?xml version="1.0" encoding="UTF-8"?>
    <rss version="2.0" xmlns:atom="http://www.w3.org/2005/Atom" xmlns:content="http://purl.org/rss/1.0/modules/content/">
      <channel>
        <title>Example RSS</title>
        <description>A small RSS feed</description>
        <link>https://example.com/</link>
        <atom:link rel="self" href="https://example.com/feed.xml" type="application/rss+xml" />
        <lastBuildDate>Fri, 26 Jun 2026 12:34:56 GMT</lastBuildDate>
        <managingEditor>ada@example.com</managingEditor>
        <category domain="https://example.com/tags">ruby</category>
        <item>
          <guid>tag:example.com,2026:entry-1</guid>
          <title>First RSS post</title>
          <link>https://example.com/first</link>
          <description>Hello summary</description>
          <content:encoded>&lt;p&gt;Hello&lt;/p&gt;</content:encoded>
          <pubDate>Thu, 25 Jun 2026 10:00:00 GMT</pubDate>
          <author>author@example.com</author>
          <category>rss</category>
          <enclosure url="https://example.com/audio.mp3" type="audio/mpeg" length="123" />
        </item>
      </channel>
    </rss>
  XML

  def test_parses_rss_feed_metadata
    feed = FeedParser.parse(SAMPLE)

    assert_equal "Example RSS", feed.title
    assert_equal "A small RSS feed", feed.description
    assert_equal "https://example.com/", feed.url
    assert_equal "https://example.com/feed.xml", feed.feed_url
    assert_equal [FeedParser::Person.new(email: "ada@example.com")], feed.authors
    assert_equal [FeedParser::Category.new(term: "ruby", scheme: "https://example.com/tags")], feed.categories
  end

  def test_parses_rss_items
    entry = FeedParser.parse(SAMPLE).entries.fetch(0)

    assert_equal "tag:example.com,2026:entry-1", entry.id
    assert_equal "First RSS post", entry.title
    assert_equal "https://example.com/first", entry.url
    assert_equal "Hello summary", entry.summary
    assert_equal "<p>Hello</p>", entry.content
    assert_equal [FeedParser::Person.new(email: "author@example.com")], entry.authors
    assert_equal [FeedParser::Category.new(term: "rss")], entry.categories
    assert_equal "https://example.com/audio.mp3", entry.links.find { |link| link.rel == "enclosure" }.href
  end
end
