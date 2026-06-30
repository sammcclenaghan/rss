# frozen_string_literal: true

require "test_helper"

class Post
  class FetcherTest < ActiveSupport::TestCase
    setup do
      @provider = Feed::Provider.new(config: Feed::Config.new.parse("#{feeds(:xkcd).url} XKCD[#abc] #comics"))
      @list = @provider.all
    end

    test "returns latest posts for the feed list" do
      posts = Post::Fetcher.new.latest(feed_list: @list)
      assert_includes posts.map(&:title), posts(:recent_xkcd).title
    end

    test "attaches configured feed metadata to each post" do
      post = Post::Fetcher.new.latest(feed_list: @list).first
      assert_equal "XKCD", post.feed_config.name
      assert_equal "#abc", post.feed_config.color
    end

    test "filters by query" do
      posts = Post::Fetcher.new.latest(feed_list: @list, query: "Ancient")
      assert_equal [ posts(:old_xkcd).title ], posts.map(&:title)
    end

    test "returns empty when the feed list is empty" do
      assert_empty Post::Fetcher.new.latest(feed_list: Feed::List.new)
    end
  end
end
