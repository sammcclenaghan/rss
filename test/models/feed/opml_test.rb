require "test_helper"

class Feed::OpmlTest < ActiveSupport::TestCase
  test "exports feeds grouped into category outlines" do
    config = Feed::Config.new
    config.add("https://a.com/feed.xml", name: "Feed A", tags: %w[#tech], color: "#abc")
    config.add("https://b.com/feed.xml", name: "Feed B", tags: [])

    xml = Feed::Opml.export(config)

    assert_includes xml, "xmlUrl='https://a.com/feed.xml'"
    assert_includes xml, "text='Feed A'"
    assert_includes xml, "text='tech'"          # category outline for the tag
    assert_includes xml, "xmlUrl='https://b.com/feed.xml'"
  end

  test "imports feeds and derives tags from the enclosing category" do
    xml = <<~OPML
      <?xml version="1.0"?>
      <opml version="2.0"><body>
        <outline text="News">
          <outline type="rss" text="One" xmlUrl="https://one.example/feed.xml"/>
        </outline>
        <outline type="rss" text="Two" xmlUrl="https://two.example/feed.xml"/>
      </body></opml>
    OPML

    config = Feed::Config.new
    count = Feed::Opml.import(xml, into: config)

    assert_equal 2, count
    assert_equal "One", config.name_for("https://one.example/feed.xml")
    assert_equal %w[#News], config.tags_for("https://one.example/feed.xml")
    assert_empty config.tags_for("https://two.example/feed.xml")
  end

  test "import ignores outlines without a feed url and bad xml" do
    assert_equal 0, Feed::Opml.import("not xml at all", into: Feed::Config.new)
    assert_equal 0, Feed::Opml.import("<opml><body><outline text='folder'/></body></opml>", into: Feed::Config.new)
  end

  test "export/import round-trips feed urls" do
    config = Feed::Config.new
    config.add("https://a.com/feed.xml", name: "Feed A", tags: %w[#tech])
    config.add("https://b.com/feed.xml", name: "Feed B", tags: [])

    reimported = Feed::Config.new
    Feed::Opml.import(Feed::Opml.export(config), into: reimported)

    assert_equal config.feed_urls.sort, reimported.feed_urls.sort
  end
end
