# frozen_string_literal: true

require 'test_helper'

class FeedjiraFixtureTest < Minitest::Test
  EXPECTED_FIXTURES = {
    'atom_simple_single_entry.xml' => {
      title: 'Example Feed',
      url: 'http://example.org/',
      feed_url: nil,
      entries: 1,
      first_entry_title: 'Atom-Powered Robots Run Amok'
    },
    'atom_simple_single_entry_link_self.xml' => {
      title: 'Example Feed',
      url: 'http://example.org/atom.xml',
      feed_url: 'http://example.org/atom.xml',
      entries: 1,
      first_entry_title: 'Atom-Powered Robots Run Amok'
    },
    'google_alerts_atom.xml' => {
      title: 'Google Alert - Slack',
      url: 'https://www.google.com/alerts/feeds/04175468913983673025/4428013283581841004',
      feed_url: 'https://www.google.com/alerts/feeds/04175468913983673025/4428013283581841004',
      entries: 20,
      first_entry_title: 'Report offers Prediction of Automotive <b>Slack</b> Market by Top key players like Haldex, Meritor, Bendix ...'
    },
    'youtube_atom.xml' => {
      title: 'Google',
      url: 'http://www.youtube.com/user/Google',
      feed_url: 'http://www.youtube.com/feeds/videos.xml?user=google',
      entries: 15,
      first_entry_title: 'The Google app: Questions Title'
    },
    'TechCrunch.xml' => {
      title: 'TechCrunch',
      url: 'http://techcrunch.com',
      feed_url: 'http://feeds.feedburner.com/Techcrunch',
      entries: 20,
      first_entry_title: 'Angie’s List Sets Price Range IPO At $11 To $13 Per Share; Valued At Over $600M'
    },
    'TenderLovemaking.xml' => {
      title: 'Tender Lovemaking',
      url: 'http://tenderlovemaking.com',
      feed_url: 'http://tenderlovemaking.com/feed/',
      entries: 10,
      first_entry_title: 'Nokogiri’s Slop Feature'
    },
    'PaulDixExplainsNothing.xml' => {
      title: 'Paul Dix Explains Nothing',
      url: 'http://www.pauldix.net/',
      feed_url: 'http://feeds.feedburner.com/PaulDixExplainsNothing',
      entries: 5,
      first_entry_title: 'Making a Ruby C library even faster'
    },
    'RSSWithComments.xml' => {
      title: 'Hacker News',
      url: 'https://news.ycombinator.com/',
      feed_url: nil,
      entries: 30,
      first_entry_title: 'AWS Lambda Function URLs: Built-In HTTPS Endpoints for Lambda'
    }
  }.freeze

  EXPECTED_FIXTURES.each do |name, expected|
    define_method("test_parses_feedjira_#{name.tr('.-', '__')}") do
      feed = parse_fixture("feedjira/#{name}")

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
