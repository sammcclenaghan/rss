# frozen_string_literal: true

require "test_helper"

class FeedjiraFixtureTest < Minitest::Test
  ATOM_FIXTURES = %w[
    atom_simple_single_entry.xml
    atom_simple_single_entry_link_self.xml
    google_alerts_atom.xml
    youtube_atom.xml
  ].freeze

  RSS_FIXTURES = %w[
    TechCrunch.xml
    TenderLovemaking.xml
    PaulDixExplainsNothing.xml
    RSSWithComments.xml
  ].freeze

  (ATOM_FIXTURES + RSS_FIXTURES).each do |name|
    define_method("test_parses_feedjira_#{name.tr('.-', '__')}") do
      feed = parse_fixture("feedjira/#{name}")

      assert_instance_of FeedParser::Feed, feed
      assert feed.title || feed.description, "expected #{name} to have feed metadata"
      assert_operator feed.entries.size, :>, 0, "expected #{name} to have entries"
    end
  end
end
