# frozen_string_literal: true

require 'test_helper'

class RSSTest < Minitest::Test
  SAMPLE = <<~XML
    <?xml version="1.0" encoding="UTF-8"?>
    <rss version="2.0" xmlns:atom="http://www.w3.org/2005/Atom" xmlns:content="http://purl.org/rss/1.0/modules/content/" xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:itunes="http://www.itunes.com/dtds/podcast-1.0.dtd" xmlns:media="http://search.yahoo.com/mrss/">
      <channel>
        <title>Example RSS</title>
        <description>A small RSS feed</description>
        <link>https://example.com/</link>
        <atom:link rel="self" href="https://example.com/feed.xml" type="application/rss+xml" />
        <lastBuildDate>Fri, 26 Jun 2026 12:34:56 GMT</lastBuildDate>
        <managingEditor>ada@example.com</managingEditor>
        <itunes:author>Channel Podcast Author</itunes:author>
        <category domain="https://example.com/tags">ruby</category>
        <image><url>https://example.com/feed.png</url></image>
        <item>
          <guid>tag:example.com,2026:entry-1</guid>
          <title>First RSS post</title>
          <link>https://example.com/first</link>
          <description>Hello summary</description>
          <content:encoded>&lt;p&gt;Hello&lt;/p&gt;</content:encoded>
          <pubDate>Thu, 25 Jun 2026 10:00:00 GMT</pubDate>
          <author>author@example.com (RSS Author)</author>
          <category>rss</category>
          <media:thumbnail url="https://example.com/thumb.jpg" />
          <enclosure url="https://example.com/audio.mp3" type="audio/mpeg" length="123" />
        </item>
      </channel>
    </rss>
  XML

  def test_parses_rss_feed_metadata
    feed = FeedParser.parse(SAMPLE)

    assert_equal 'Example RSS', feed.title
    assert_equal 'A small RSS feed', feed.description
    assert_equal 'https://example.com/', feed.url
    assert_equal 'https://example.com/feed.xml', feed.feed_url
    assert_equal 'https://example.com/feed.png', feed.image
    assert_equal [
      FeedParser::Person.new(name: 'Channel Podcast Author'),
      FeedParser::Person.new(email: 'ada@example.com')
    ], feed.authors
    assert_equal [FeedParser::Category.new(term: 'ruby', scheme: 'https://example.com/tags')], feed.categories
  end

  def test_rss_content_does_not_fall_back_to_description
    rss = <<~XML
      <rss><channel><item>
        <title>Summary Only</title>
        <link>https://example.com/summary-only</link>
        <guid>summary-only</guid>
        <description>Short teaser only.</description>
        <pubDate>Tue, 10 Jun 2025 09:00:00 +0000</pubDate>
      </item></channel></rss>
    XML

    entry = FeedParser.parse(rss).entries.fetch(0)

    assert_equal 'Short teaser only.', entry.summary
    assert_nil entry.content
  end

  def test_rss_supports_a10_content
    rss = <<~XML
      <rss xmlns:a10="http://www.w3.org/2005/Atom"><channel><item>
        <title>Atom Content Namespace</title>
        <link>https://example.com/a10</link>
        <guid>a10</guid>
        <description>Short teaser.</description>
        <a10:content>Full content from Atom namespace.</a10:content>
        <pubDate>Tue, 10 Jun 2025 09:00:00 +0000</pubDate>
      </item></channel></rss>
    XML

    entry = FeedParser.parse(rss).entries.fetch(0)

    assert_equal 'Short teaser.', entry.summary
    assert_equal 'Full content from Atom namespace.', entry.content
  end

  def test_rss_supports_dc_creator_author
    rss = <<~XML
      <rss xmlns:dc="http://purl.org/dc/elements/1.1/"><channel><item>
        <title>DC Creator</title>
        <link>https://example.com/dc</link>
        <guid>dc</guid>
        <dc:creator>Jane Creator</dc:creator>
        <pubDate>Tue, 10 Jun 2025 09:00:00 +0000</pubDate>
      </item></channel></rss>
    XML

    entry = FeedParser.parse(rss).entries.fetch(0)

    assert_equal [FeedParser::Person.new(name: 'Jane Creator')], entry.authors
  end

  def test_rss_item_inherits_channel_author
    rss = <<~XML
      <rss><channel>
        <managingEditor>editor@example.com</managingEditor>
        <item>
          <title>Inherited Author</title>
          <link>https://example.com/inherited</link>
          <guid>inherited</guid>
          <pubDate>Tue, 10 Jun 2025 09:00:00 +0000</pubDate>
        </item>
      </channel></rss>
    XML

    entry = FeedParser.parse(rss).entries.fetch(0)

    assert_equal [FeedParser::Person.new(email: 'editor@example.com')], entry.authors
  end

  def test_rss_uses_image_enclosure_as_entry_image
    rss = <<~XML
      <rss><channel><item>
        <title>Image Enclosure</title>
        <link>https://example.com/image</link>
        <guid>image</guid>
        <enclosure url="https://example.com/image.jpg" type="image/jpeg" length="123" />
        <pubDate>Tue, 10 Jun 2025 09:00:00 +0000</pubDate>
      </item></channel></rss>
    XML

    entry = FeedParser.parse(rss).entries.fetch(0)

    assert_equal 'https://example.com/image.jpg', entry.image
  end

  def test_parses_rss_items
    entry = FeedParser.parse(SAMPLE).entries.fetch(0)

    assert_equal 'tag:example.com,2026:entry-1', entry.id
    assert_equal 'First RSS post', entry.title
    assert_equal 'https://example.com/first', entry.url
    assert_equal 'Hello summary', entry.summary
    assert_equal '<p>Hello</p>', entry.content
    assert_equal 'https://example.com/thumb.jpg', entry.image
    assert_equal [FeedParser::Person.new(name: 'RSS Author', email: 'author@example.com')], entry.authors
    assert_equal [FeedParser::Category.new(term: 'rss')], entry.categories
    assert_equal 'https://example.com/audio.mp3', entry.links.find { |link| link.rel == 'enclosure' }.href
  end
end
