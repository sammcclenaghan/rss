# frozen_string_literal: true

require "test_helper"

class PrunePostsJobTest < ActiveSupport::TestCase
  setup { @previous_retention = Rails.configuration.x.rss.prune_posts_after_days }

  teardown { Rails.configuration.x.rss.prune_posts_after_days = @previous_retention }

  test "prunes posts older than the configured retention window" do
    Rails.configuration.x.rss.prune_posts_after_days = 100
    old_id = posts(:old_xkcd).id

    assert_difference -> { Post.count }, -1 do
      PrunePostsJob.perform_now
    end
    assert_not Post.exists?(old_id)
  end

  test "does nothing when no retention window is configured" do
    Rails.configuration.x.rss.prune_posts_after_days = nil

    assert_no_difference -> { Post.count } do
      PrunePostsJob.perform_now
    end
  end
end
