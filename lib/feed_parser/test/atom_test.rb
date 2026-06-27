# frozen_string_literal: true

require 'test_helper'

class AtomTest < Minitest::Test
  SAMPLE = <<~XML
    <?xml version="1.0" encoding="utf-8"?>
    <feed xmlns="http://www.w3.org/2005/Atom" xmlns:media="http://search.yahoo.com/mrss/">
      <id>tag:example.com,2026:feed</id>
      <title>Example Atom</title>
      <subtitle>A small feed</subtitle>
      <updated>2026-06-26T12:34:56Z</updated>
      <link rel="self" href="https://example.com/feed.atom" type="application/atom+xml" />
      <link rel="alternate" href="https://example.com/" type="text/html" hreflang="en" title="Home" length="42" />
      <author>
        <name>Ada Lovelace</name>
        <email>ada@example.com</email>
      </author>
      <category term="ruby" scheme="https://example.com/tags" label="Ruby" />
      <logo>https://example.com/logo.png</logo>
      <entry>
        <id>tag:example.com,2026:entry-1</id>
        <title>First post</title>
        <link href="https://example.com/first" />
        <summary>Hello summary</summary>
        <category term="atom" />
        <media:thumbnail url="https://example.com/atom-thumb.jpg" />
        <content type="html">&lt;p&gt;Hello&lt;/p&gt;</content>
        <published>2026-06-25T10:00:00Z</published>
        <updated>2026-06-25T11:00:00Z</updated>
      </entry>
    </feed>
  XML

  def test_parses_atom_feed_metadata
    feed = FeedParser.parse(SAMPLE)

    assert_equal 'tag:example.com,2026:feed', feed.id
    assert_equal 'Example Atom', feed.title
    assert_equal 'A small feed', feed.description
    assert_equal 'https://example.com/', feed.url
    assert_equal 'https://example.com/feed.atom', feed.feed_url
    assert_equal ['https://example.com/feed.atom', 'https://example.com/'], feed.links.map(&:href)
    assert_equal FeedParser::Link.new(
      href: 'https://example.com/',
      rel: 'alternate',
      type: 'text/html',
      hreflang: 'en',
      title: 'Home',
      length: 42
    ), feed.links.fetch(1)
    assert_equal 'https://example.com/logo.png', feed.image
    assert_equal [FeedParser::Person.new(name: 'Ada Lovelace', email: 'ada@example.com')], feed.authors
    assert_equal [FeedParser::Category.new(term: 'ruby', scheme: 'https://example.com/tags', label: 'Ruby')],
                 feed.categories
    assert_equal Time.utc(2026, 6, 26, 12, 34, 56), feed.updated
  end

  def test_parses_atom_entries
    entry = FeedParser.parse(SAMPLE).entries.fetch(0)

    assert_equal 'tag:example.com,2026:entry-1', entry.id
    assert_equal 'First post', entry.title
    assert_equal 'https://example.com/first', entry.url
    assert_equal 'Hello summary', entry.summary
    assert_equal '<p>Hello</p>', entry.content
    assert_equal Time.utc(2026, 6, 25, 10, 0, 0), entry.published
    assert_equal Time.utc(2026, 6, 25, 11, 0, 0), entry.updated
    assert_equal 'https://example.com/atom-thumb.jpg', entry.image
    assert_equal [FeedParser::Person.new(name: 'Ada Lovelace', email: 'ada@example.com')], entry.authors
    assert_equal [FeedParser::Category.new(term: 'atom')], entry.categories
  end

  def test_atom_content_falls_back_to_summary_when_content_is_missing
    xml = SAMPLE.sub(%r{\s*<content type="html">&lt;p&gt;Hello&lt;/p&gt;</content>}, '')

    entry = FeedParser.parse(xml).entries.fetch(0)

    assert_equal 'Hello summary', entry.summary
    assert_equal 'Hello summary', entry.content
  end

  def test_entry_author_overrides_feed_author
    xml = SAMPLE.sub(
      '<published>2026-06-25T10:00:00Z</published>',
      '<author><name>Entry Author</name></author><published>2026-06-25T10:00:00Z</published>'
    )

    entry = FeedParser.parse(xml).entries.fetch(0)

    assert_equal [FeedParser::Person.new(name: 'Entry Author')], entry.authors
  end

  def test_rejects_non_atom_xml
    error = assert_raises(FeedParser::ParseError) do
      FeedParser.parse('<html />')
    end

    assert_equal 'unsupported feed format', error.message
  end
end
