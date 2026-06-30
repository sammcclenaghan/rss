# frozen_string_literal: true

require "test_helper"

class Feed
  class ProviderTest < ActiveSupport::TestCase
    def provider_for(config_text)
      Feed::Provider.new(config: Feed::Config.new.parse(config_text))
    end

    test "reuses existing feed records and creates missing ones" do
      config = "#{feeds(:xkcd).url} XKCD #comics\nhttps://example.com/new.xml New #blog"

      assert_difference -> { Feed.count }, 1 do
        provider = provider_for(config)
        assert_equal 2, provider.all.size
      end
    end

    test "auto-enqueues a refresh for newly-created feeds" do
      config = "https://example.com/fresh.xml Fresh #blog"

      assert_enqueued_with(job: RefreshFeedJob) do
        new_feed = nil
        assert_difference -> { Feed.count }, 1 do
          new_feed = provider_for(config).all.first.feed
        end
        assert_equal "https://example.com/fresh.xml", new_feed.url
      end
    end

    test "does not enqueue a refresh when refresh_new_feeds is false" do
      config = "https://example.com/staged.xml Staged #blog"

      assert_no_enqueued_jobs only: RefreshFeedJob do
        Feed::Provider.new(config: Feed::Config.new.parse(config), refresh_new_feeds: false)
      end
    end

    test "does not enqueue a refresh for already-existing feeds" do
      config = "#{feeds(:xkcd).url} XKCD #comics"

      assert_no_enqueued_jobs only: RefreshFeedJob do
        provider_for(config).all
      end
    end

    test "all returns every configured feed" do
      provider = provider_for("#{feeds(:xkcd).url} XKCD\nhttps://example.com/a.xml A")
      assert_equal 2, provider.all.size
    end

    test "visible excludes hidden feeds" do
      provider = provider_for("#{feeds(:xkcd).url} XKCD\n-https://example.com/hidden.xml Hidden")
      assert_equal 1, provider.visible.size
    end

    test "for_tag filters by tag with or without the hash" do
      provider = provider_for("#{feeds(:xkcd).url} XKCD #comics\nhttps://example.com/a.xml A #news")
      assert_equal 1, provider.for_tag("comics").size
      assert_equal 1, provider.for_tag("#comics").size
    end

    test "for_url returns a single-feed list or empty" do
      provider = provider_for("#{feeds(:xkcd).url} XKCD")
      assert_equal 1, provider.for_url(feeds(:xkcd).url).size
      assert_equal 0, provider.for_url("https://nope.test/x.xml").size
    end

    test "get touches last_accessed_at" do
      freeze_time do
        provider = provider_for("#{feeds(:xkcd).url} XKCD")
        provider.get(feeds(:xkcd).url)
        assert_equal Time.current.to_i, feeds(:xkcd).reload.last_accessed_at
      end
    end
  end
end
