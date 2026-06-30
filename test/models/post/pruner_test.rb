# frozen_string_literal: true

require "test_helper"

class Post
  class PrunerTest < ActiveSupport::TestCase
    setup { @pruner = Post::Pruner.new }

    test "deletes posts older than the retention window" do
      old_id = posts(:old_xkcd).id
      recent_id = posts(:recent_xkcd).id

      assert_difference -> { Post.count }, -1 do
        assert_equal 1, @pruner.prune(100)
      end
      assert_not Post.exists?(old_id)
      assert Post.exists?(recent_id)
    end

    test "keeps everything when nothing is old enough" do
      assert_no_difference -> { Post.count } do
        assert_equal 0, @pruner.prune(10_000)
      end
    end

    test "removes the thumbnail file for pruned posts" do
      file = Rails.root.join("public/storage", posts(:old_xkcd).thumbnail)
      file.dirname.mkpath
      file.binwrite("fake-image")

      @pruner.prune(100)
      assert_not file.exist?
    ensure
      file&.delete if file&.exist?
    end
  end
end
