require "test_helper"

class Feed::RefresherTest < ActiveSupport::TestCase
  setup do
    @feed = feeds(:basecamp)
    @incoming = [ build_incoming(guid: "fresh-1", title: "Fresh") ]
  end

  test "creates new posts and stamps the feed as fetched" do
    assert_difference -> { @feed.posts.count }, 1 do
      refresher(@incoming).refresh(@feed)
    end
    assert @feed.reload.last_fetched_at.positive?
  end

  test "updates an existing post in place instead of duplicating" do
    existing = posts(:basecamp_post)
    incoming = [ build_incoming(guid: existing.guid, title: "Updated Title", url: existing.url) ]

    assert_no_difference -> { @feed.posts.count } do
      refresher(incoming).refresh(@feed)
    end
    assert_equal "Updated Title", existing.reload.title
  end

  test "enqueues thumbnail jobs for new posts when enabled" do
    assert_enqueued_with(job: FetchPostThumbnailJob) do
      refresher(@incoming, load_thumbnails: true).refresh(@feed)
    end
  end

  test "passes feed-provided image urls to thumbnail jobs" do
    incoming = [ build_incoming(guid: "img-1", title: "Image", feed_image_url: "https://cdn.example.com/image.jpg") ]

    assert_enqueued_with(job: FetchPostThumbnailJob) do
      refresher(incoming, load_thumbnails: true).refresh(@feed)
    end

    job = enqueued_jobs.find { |enqueued| enqueued[:job] == FetchPostThumbnailJob }
    assert_equal "https://cdn.example.com/image.jpg", job[:args].last
  end

  test "does not enqueue thumbnail jobs when disabled" do
    assert_no_enqueued_jobs only: FetchPostThumbnailJob do
      refresher(@incoming, load_thumbnails: false).refresh(@feed)
    end
  end

  test "does not enqueue thumbnail jobs for posts that already existed" do
    existing = posts(:basecamp_post)
    incoming = [ build_incoming(guid: existing.guid, title: existing.title, url: existing.url) ]

    assert_no_enqueued_jobs only: FetchPostThumbnailJob do
      refresher(incoming, load_thumbnails: true).refresh(@feed)
    end
  end

  private
    def refresher(posts, load_thumbnails: false)
      Feed::Refresher.new(fetcher: FakeFeedFetcher.new(posts),
        load_thumbnails: load_thumbnails)
    end

    def build_incoming(guid:, title:, url: "https://example.com/#{guid}", feed_image_url: nil)
      Post.new(title: title, url: url, guid: guid, description: "Body", published_at: 1.hour.ago.to_i).tap do |post|
        post.feed_image_url = feed_image_url
      end
    end
end
