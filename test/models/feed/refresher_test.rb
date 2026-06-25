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

  test "stores sanitized feed content for posts" do
    incoming = [ build_incoming(guid: "c-1", title: "C", raw_content: "<p>Hello <script>alert(1)</script>world.</p>") ]

    refresher(incoming, load_content: true).refresh(@feed)

    content = @feed.posts.find_by(guid: "c-1").content
    assert_not_nil content
    assert_equal Post::Content::FEED, content.source
    assert_includes content.body, "Hello"
    assert_not_includes content.body, "script"
    assert content.word_count.positive?
  end

  test "does not store content when disabled" do
    incoming = [ build_incoming(guid: "c-2", title: "C", raw_content: "<p>Body.</p>") ]

    refresher(incoming, load_content: false).refresh(@feed)

    assert_nil @feed.posts.find_by(guid: "c-2").content
  end

  test "does not replace a longer existing body with a shorter feed body" do
    existing = posts(:basecamp_post)
    Post::Content.create!(post: existing, body: "<p>#{'word ' * 50}</p>",
      source: Post::Content::EXTRACTED, word_count: 50)
    incoming = [ build_incoming(guid: existing.guid, title: existing.title, url: existing.url,
      raw_content: "<p>tiny</p>") ]

    refresher(incoming, load_content: true).refresh(@feed)

    assert_equal Post::Content::EXTRACTED, existing.reload.content.source
  end

  test "enqueues extraction for new posts that have no feed content" do
    incoming = [ build_incoming(guid: "x-1", title: "X") ]

    assert_enqueued_with(job: ExtractPostContentJob) do
      refresher(incoming, load_content: true, extract_content: true).refresh(@feed)
    end
  end

  test "does not enqueue extraction when the feed provided content" do
    incoming = [ build_incoming(guid: "x-2", title: "X", raw_content: "<p>Full body here.</p>") ]

    assert_no_enqueued_jobs only: ExtractPostContentJob do
      refresher(incoming, load_content: true, extract_content: true).refresh(@feed)
    end
  end

  test "does not enqueue extraction for posts that already existed" do
    existing = posts(:basecamp_post)
    incoming = [ build_incoming(guid: existing.guid, title: existing.title, url: existing.url) ]

    assert_no_enqueued_jobs only: ExtractPostContentJob do
      refresher(incoming, extract_content: true).refresh(@feed)
    end
  end

  test "does not enqueue extraction when disabled" do
    incoming = [ build_incoming(guid: "x-3", title: "X") ]

    assert_no_enqueued_jobs only: ExtractPostContentJob do
      refresher(incoming, extract_content: false).refresh(@feed)
    end
  end

  private
    def refresher(posts, load_thumbnails: false, load_content: false, extract_content: false)
      Feed::Refresher.new(fetcher: FakeFeedFetcher.new(posts),
        load_thumbnails: load_thumbnails, load_content: load_content, extract_content: extract_content)
    end

    def build_incoming(guid:, title:, url: "https://example.com/#{guid}", raw_content: nil)
      Post.new(title: title, url: url, guid: guid, description: "Body", published_at: 1.hour.ago.to_i)
        .tap { |post| post.raw_content = raw_content }
    end
end
