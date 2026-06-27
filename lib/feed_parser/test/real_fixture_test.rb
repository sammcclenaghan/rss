# frozen_string_literal: true

require 'test_helper'

class RealFixtureTest < Minitest::Test
  Dir[File.expand_path('fixtures/real/*.{xml,json}', __dir__)].sort.each do |path|
    name = File.basename(path)

    define_method("test_smoke_parses_real_#{name.tr('.-', '__')}") do
      feed = parse_fixture("real/#{name}")

      assert_instance_of FeedParser::Feed, feed
      assert feed.title || feed.description, "expected #{name} to have metadata"
      assert_operator feed.entries.size, :>, 0, "expected #{name} to have entries"
    end
  end

  EXPECTED_FIXTURES = {
    'android_developers_3ddc84_1ebe0fd7.xml' => {
      title: 'Android Developers Blog',
      url: 'https://android-developers.googleblog.com/',
      feed_url: 'https://www.blogger.com/feeds/6755709643044947179/posts/default',
      entries: 25,
      first_entry_title: 'Expanded billing choice and lower fees on Google Play'
    },
    'apple_developer_555555_3179ddb8.xml' => {
      title: 'Latest News - Apple Developer',
      url: 'https://developer.apple.com/news/',
      feed_url: 'https://developer.apple.com/news/rss/news.rss',
      entries: 145,
      first_entry_title: 'Design kits for iOS, iPadOS, and macOS 27 are here'
    },
    'apple_newsroom_555555_7e621a3a.xml' => {
      title: 'Apple Newsroom',
      url: 'https://www.apple.com/newsroom/rss-feed.rss',
      feed_url: 'https://www.apple.com/newsroom/rss-feed.rss',
      entries: 20,
      first_entry_title: 'Apple announces changes to iOS in Brazil'
    },
    'aws_machine_learning_ff9900_458f4ae1.xml' => {
      title: 'Artificial Intelligence',
      url: 'https://aws.amazon.com/blogs/machine-learning/',
      feed_url: 'https://aws.amazon.com/blogs/machine-learning/feed/',
      entries: 20,
      first_entry_title: 'Build interactive PDF text extraction from Amazon S3'
    },
    'macstories_ff3b30_3316ff62.xml' => {
      title: 'MacStories',
      url: 'https://www.macstories.net/',
      feed_url: 'https://www.macstories.net/feed/',
      entries: 30,
      first_entry_title: 'Podcast Rewind: WWDC Reflections, Thunderbolt Hubs, and Prime Day Finds'
    },
    'marco_org_405060_4b02e926.xml' => {
      title: 'Marco.org',
      url: 'https://marco.org/',
      feed_url: nil,
      entries: 20,
      first_entry_title: 'A letter to John Ternus'
    },
    'six_colors_007aff_e78457d0.xml' => {
      title: 'Six Colors',
      url: 'https://sixcolors.com',
      feed_url: 'https://sixcolors.com/feed/',
      entries: 75,
      first_entry_title: '(Sponsor) Mojave Paint'
    },
    'the_sweet_setup_ff9500_cdec4e9f.xml' => {
      title: 'The Sweet Setup',
      url: 'https://thesweetsetup.com/',
      feed_url: 'https://thesweetsetup.com/feed/',
      entries: 15,
      first_entry_title: '4 flaws of a busy calendar'
    }
  }.freeze

  EXPECTED_FIXTURES.each do |name, expected|
    define_method("test_parses_real_#{name.tr('.-', '__')}") do
      feed = parse_fixture("real/#{name}")

      assert_instance_of FeedParser::Feed, feed
      assert_equal expected.fetch(:title), feed.title
      assert_equal expected.fetch(:url), feed.url
      if expected.fetch(:feed_url).nil?
        assert_nil feed.feed_url
      else
        assert_equal expected.fetch(:feed_url), feed.feed_url
      end
      assert_equal expected.fetch(:entries), feed.entries.size
      assert_equal expected.fetch(:first_entry_title), feed.entries.first.title
    end
  end
end
