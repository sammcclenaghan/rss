require "test_helper"

class PostsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @previous_config_file = Rails.configuration.x.rss.config_file
    Rails.configuration.x.rss.config_file = file_fixture("feeds.txt").to_s
  end

  teardown { Rails.configuration.x.rss.config_file = @previous_config_file }

  test "index renders posts" do
    get root_path
    assert_response :success
    assert_select "h2", /Posts/
    assert_select ".rss-post", minimum: 1
  end

  test "index refreshes outdated feeds" do
    feeds(:xkcd).update!(last_fetched_at: 0)
    assert_enqueued_with(job: RefreshFeedJob) do
      get root_path
    end
  end

  test "tag filters posts to a tag" do
    get tag_posts_path("comics")
    assert_response :success
    assert_select "h2", /#comics/
  end

  test "feed filters posts to a single feed" do
    get feed_posts_path(Feed::Config.encode_feed_url(feeds(:xkcd).url))
    assert_response :success
    assert_select "span", "XKCD"
  end

  test "query narrows the result set" do
    get root_path, params: { query: "Ancient" }
    assert_response :success
    assert_select ".rss-post", 1
  end

  test "read posts are marked with the is-read class" do
    ReadPost.create!(post: posts(:recent_xkcd))
    get root_path
    assert_response :success
    assert_select ".rss-post.is-read", 1
  end

  test "unread filter hides read posts" do
    ReadPost.create!(post: posts(:recent_xkcd))
    get root_path, params: { unread: "1" }
    assert_response :success
    # XKCD has two fixture posts; one is now read, leaving a single unread post.
    assert_select ".rss-post", 1
    assert_select ".rss-post.is-read", 0
  end

  test "sidebar shows an unread count per feed" do
    get root_path
    assert_response :success
    assert_select "h4", /unread/
  end

  test "search form submits globally on the homepage" do
    get root_path
    assert_select "form[method=get][action=?]", root_path
  end

  test "search form scopes to the current tag" do
    get tag_posts_path("comics")
    assert_select "form[method=get][action=?]", tag_posts_path("comics")
  end

  test "query narrows results within a tag scope" do
    get tag_posts_path("comics"), params: { query: "Ancient" }
    assert_response :success
    assert_select ".rss-post", 1
    assert_select "h3", /An Ancient Comic/
  end

  test "post links open the reader outside the turbo frame" do
    get root_path
    assert_response :success
    # The list lives in the "posts" turbo frame; reader links must target _top
    # or Turbo looks for a #posts frame in the reader response and 404s the frame.
    assert_select "a[data-turbo-frame=_top][href=?]", post_path(posts(:recent_xkcd))
  end

  test "show renders the reader with captured content" do
    post = posts(:recent_xkcd)
    Post::Content.create!(post: post, body: "<p>The full article body.</p>",
      source: Post::Content::EXTRACTED, word_count: 250)

    get post_path(post)

    assert_response :success
    assert_select "h1", /A Recent Comic/
    assert_select ".reader-eyebrow", /XKCD/
    assert_select ".reader-content p", /full article body/
    assert_select "span", /2 min read/
  end

  test "show marks the post as read" do
    post = posts(:recent_xkcd)

    assert_difference -> { ReadPost.where(post: post).count }, 1 do
      get post_path(post)
    end
    assert_response :success
  end

  test "show falls back to the description when there is no captured content" do
    post = posts(:recent_xkcd)

    get post_path(post)

    assert_response :success
    assert_select ".reader-content", /Something funny happened/
    assert_select "a[href=?]", post.url, /Read the original/
  end
end
