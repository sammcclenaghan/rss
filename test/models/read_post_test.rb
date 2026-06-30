# frozen_string_literal: true

require "test_helper"

class ReadPostTest < ActiveSupport::TestCase
  test "Post.read and Post.unread partition by read state" do
    read = posts(:recent_xkcd)
    ReadPost.create!(post: read)

    assert_includes Post.read, read
    assert_not_includes Post.unread, read
    assert_includes Post.unread, posts(:old_xkcd)
  end

  test "read? prefers the transient flag when set" do
    post = posts(:recent_xkcd)

    post.read_state = true
    assert post.read?

    post.read_state = false
    assert_not post.read?
  end

  test "read? falls back to a lookup when not preloaded" do
    post = posts(:recent_xkcd)
    assert_not post.read?

    ReadPost.create!(post: post)
    assert post.reload.read?
  end

  test "deleting a post removes its read record via the database cascade" do
    post = posts(:recent_xkcd)
    ReadPost.create!(post: post)

    # Feeds delete their posts with delete_all (no callbacks), so cleanup must
    # come from the database-level foreign key cascade.
    Post.where(id: post.id).delete_all

    assert_equal 0, ReadPost.where(post_id: post.id).count
  end
end
