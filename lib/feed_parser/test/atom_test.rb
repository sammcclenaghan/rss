# frozen_string_literal: true

require "test_helper"

class AtomTest < Minitest::Test
  SAMPLE = <<~XML
    <?xml version="1.0" encoding="utf-8"?>
    <feed xmlns="http://www.w3.org/2005/Atom">
      <id>tag:example.com,2026:feed</id>
      <title>Example Atom</title>
      <subtitle>A small feed</subtitle>
      <updated>2026-06-26T12:34:56Z</updated>
      <link rel="self" href="https://example.com/feed.atom" />
      <link rel="alternate" href="https://example.com/" />
      <author>
        <name>Ada Lovelace</name>
        <email>ada@example.com</email>
      </author>
      <entry>
        <id>tag:example.com,2026:entry-1</id>
        <title>First post</title>
        <link href="https://example.com/first" />
        <summary>Hello summary</summary>
        <content type="html">&lt;p&gt;Hello&lt;/p&gt;</content>
        <published>2026-06-25T10:00:00Z</published>
        <updated>2026-06-25T11:00:00Z</updated>
      </entry>
    </feed>
  XML

  def test_parses_atom_feed_metadata
    feed = FeedParser.parse(SAMPLE)

    assert_equal "tag:example.com,2026:feed", feed.id
    assert_equal "Example Atom", feed.title
    assert_equal "A small feed", feed.description
    assert_equal "https://example.com/", feed.url
    assert_equal "https://example.com/feed.atom", feed.feed_url
    assert_equal ["https://example.com/feed.atom", "https://example.com/"], feed.links
    assert_equal [{ name: "Ada Lovelace", email: "ada@example.com" }.freeze], feed.authors
    assert_equal Time.utc(2026, 6, 26, 12, 34, 56), feed.updated
  end

  def test_parses_atom_entries
    entry = FeedParser.parse(SAMPLE).entries.fetch(0)

    assert_equal "tag:example.com,2026:entry-1", entry.id
    assert_equal "First post", entry.title
    assert_equal "https://example.com/first", entry.url
    assert_equal "Hello summary", entry.summary
    assert_equal "<p>Hello</p>", entry.content
    assert_equal Time.utc(2026, 6, 25, 10, 0, 0), entry.published
    assert_equal Time.utc(2026, 6, 25, 11, 0, 0), entry.updated
  end

  def test_rejects_non_atom_xml
    error = assert_raises(FeedParser::ParseError) do
      FeedParser.parse("<rss><channel /></rss>")
    end

    assert_equal "not an Atom feed", error.message
  end
end
