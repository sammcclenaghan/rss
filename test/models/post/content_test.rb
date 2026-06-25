require "test_helper"

class Post::ContentTest < ActiveSupport::TestCase
  setup { @post = posts(:basecamp_post) }

  test "capture fills empty content and counts words" do
    content = Post::Content.capture(@post, "<p>one two three</p>", source: Post::Content::FEED)

    assert content.persisted?
    assert_equal 3, content.word_count
    assert_equal Post::Content::FEED, content.source
  end

  test "capture ignores blank bodies" do
    assert_nil Post::Content.capture(@post, "  ", source: Post::Content::FEED)
    assert_nil @post.reload.content
  end

  test "capture does not shrink existing content" do
    Post::Content.capture(@post, "<p>#{'word ' * 20}</p>", source: Post::Content::EXTRACTED)
    Post::Content.capture(@post, "<p>short</p>", source: Post::Content::FEED)

    assert_equal Post::Content::EXTRACTED, @post.reload.content.source
  end

  test "capture is a no-op when the body is unchanged" do
    Post::Content.capture(@post, "<p>same body here</p>", source: Post::Content::FEED)

    assert_no_changes -> { @post.reload.content.updated_at } do
      Post::Content.capture(@post, "<p>same body here</p>", source: Post::Content::FEED)
    end
  end
end
