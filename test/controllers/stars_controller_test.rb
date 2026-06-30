# frozen_string_literal: true

require "test_helper"

class StarsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @previous_config_file = Rails.configuration.x.rss.config_file
    Rails.configuration.x.rss.config_file = file_fixture("feeds.txt").to_s
  end

  teardown { Rails.configuration.x.rss.config_file = @previous_config_file }

  test "create stars a post" do
    target = posts(:recent_xkcd)

    assert_difference -> { StarredPost.count }, 1 do
      post post_star_path(target.id)
    end
    assert_response :no_content
    assert target.reload.starred?
  end

  test "create is idempotent" do
    target = posts(:recent_xkcd)
    StarredPost.create!(post: target)

    assert_no_difference -> { StarredPost.count } do
      post post_star_path(target.id)
    end
    assert_response :no_content
  end

  test "destroy unstars a post" do
    target = posts(:recent_xkcd)
    StarredPost.create!(post: target)

    assert_difference -> { StarredPost.count }, -1 do
      delete post_star_path(target.id)
    end
    assert_response :no_content
    assert_not target.reload.starred?
  end
end
