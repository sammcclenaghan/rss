require "test_helper"

class ReadsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @previous_config_file = Rails.configuration.x.rss.config_file
    Rails.configuration.x.rss.config_file = file_fixture("feeds.txt").to_s
  end

  teardown { Rails.configuration.x.rss.config_file = @previous_config_file }

  test "create marks a post read" do
    target = posts(:recent_xkcd)

    assert_difference -> { ReadPost.count }, 1 do
      post post_read_path(target.id)
    end
    assert_response :no_content
    assert target.reload.read?
  end

  test "create is idempotent" do
    target = posts(:recent_xkcd)
    ReadPost.create!(post: target)

    assert_no_difference -> { ReadPost.count } do
      post post_read_path(target.id)
    end
    assert_response :no_content
  end

  test "destroy marks a post unread" do
    target = posts(:recent_xkcd)
    ReadPost.create!(post: target)

    assert_difference -> { ReadPost.count }, -1 do
      delete post_read_path(target.id)
    end
    assert_response :no_content
    assert_not target.reload.read?
  end

  test "create_all marks every post in the visible scope read" do
    post read_all_posts_path

    assert_redirected_to root_path
    assert_equal feeds(:xkcd).posts.pluck(:id).sort, ReadPost.pluck(:post_id).sort
  end

  test "create_all respects the active search query" do
    post read_all_posts_path, params: { query: "Ancient" }

    read_titles = Post.where(id: ReadPost.select(:post_id)).pluck(:title)
    assert_equal [ "An Ancient Comic" ], read_titles
  end

  test "create_all scopes to a single feed" do
    post read_all_posts_path, params: { feed: feeds(:xkcd).url }

    assert_equal feeds(:xkcd).posts.pluck(:id).sort, ReadPost.pluck(:post_id).sort
  end
end
