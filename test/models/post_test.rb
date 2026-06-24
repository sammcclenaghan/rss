require "test_helper"

class PostTest < ActiveSupport::TestCase
  test "requires a guid unique within a feed" do
    duplicate = feeds(:xkcd).posts.build(
      title: "Dup", url: "https://x.test/d", guid: posts(:recent_xkcd).guid, published_at: 1.day.ago.to_i
    )
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:guid], "has already been taken"
  end

  test "allows the same guid across different feeds" do
    post = feeds(:basecamp).posts.build(
      title: "Same guid", url: "https://x.test/s", guid: posts(:recent_xkcd).guid, published_at: 1.day.ago.to_i
    )
    assert post.valid?
  end

  test "latest_first orders by published_at descending" do
    ordered = feeds(:xkcd).posts.latest_first.to_a
    assert_equal ordered.sort_by(&:published_at).reverse, ordered
  end

  test "matching searches title and description" do
    assert_includes Post.matching("Recent"), posts(:recent_xkcd)
    assert_includes Post.matching("very old"), posts(:old_xkcd)
    assert_not_includes Post.matching("Recent"), posts(:old_xkcd)
  end

  test "matching escapes LIKE wildcards" do
    assert_empty Post.matching("%")
  end

  test "published_before filters by timestamp" do
    assert_includes Post.published_before(100.days.ago), posts(:old_xkcd)
    assert_not_includes Post.published_before(100.days.ago), posts(:recent_xkcd)
  end

  test "page limits and offsets newest first" do
    first = Post.page(1, 1)
    assert_equal 1, first.size
    assert_equal Post.latest_first.first, first.first
  end
end
