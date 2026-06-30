# frozen_string_literal: true

require "test_helper"

class Feed
  class FetcherTest < ActiveSupport::TestCase
    setup { @feed = feeds(:xkcd) }

    test "fetches and parses a valid RSS feed" do
      fetcher = fetcher_returning(file_fixture_content("rss_feed.xml"), content_type: "application/xml")

      posts = fetcher.fetch(@feed)
      assert_equal 2, posts.size
      assert_equal "First Post", posts.first.title
    end

    test "returns an empty array on a non-200 response" do
      client = FakeHTTPClient.new.stub(@feed.url, status: 404)
      assert_empty Feed::Fetcher.new(client: client).fetch(@feed)
    end

    test "returns an empty array when the body is not feed-like" do
      fetcher = fetcher_returning("<!DOCTYPE html><html><body>not a feed</body></html>")
      assert_empty fetcher.fetch(@feed)
    end

    test "returns an empty array when the client fails (nil response)" do
      assert_empty Feed::Fetcher.new(client: FakeHTTPClient.new).fetch(@feed)
    end

    private

    def fetcher_returning(body, content_type: "text/html")
      client = FakeHTTPClient.new.stub(@feed.url, body: body, content_type: content_type)
      Feed::Fetcher.new(client: client)
    end
  end
end
