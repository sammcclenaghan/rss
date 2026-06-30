# frozen_string_literal: true

require "test_helper"

class FeedTest < ActiveSupport::TestCase
  test "requires a unique url" do
    duplicate = Feed.new(url: feeds(:xkcd).url)
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:url], "has already been taken"
  end

  test "outdated? is true when never fetched" do
    assert feeds(:xkcd).outdated?
  end

  test "outdated? is false when recently fetched" do
    assert_not feeds(:basecamp).outdated?
  end

  test "outdated scope returns only stale feeds" do
    assert_includes Feed.outdated, feeds(:xkcd)
    assert_not_includes Feed.outdated, feeds(:basecamp)
  end

  test "mark_fetched stamps last_fetched_at to now" do
    freeze_time do
      feeds(:xkcd).mark_fetched
      assert_equal Time.current.to_i, feeds(:xkcd).reload.last_fetched_at
    end
  end

  test "deleting a feed deletes its posts" do
    assert_difference -> { Post.count }, -feeds(:xkcd).posts.count do
      feeds(:xkcd).destroy
    end
  end
end
