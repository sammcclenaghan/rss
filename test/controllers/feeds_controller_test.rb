require "test_helper"

class FeedsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @previous_config_file = Rails.configuration.x.rss.config_file
    Rails.configuration.x.rss.config_file = file_fixture("feeds.txt").to_s
  end

  teardown { Rails.configuration.x.rss.config_file = @previous_config_file }

  test "returns feed metadata as json" do
    get feeds_info_path, params: { url: feeds(:xkcd).url }
    assert_response :success

    body = JSON.parse(response.body)
    assert_equal "XKCD", body["name"]
    assert_equal %w[#comics], body["tags"]
  end

  test "returns 404 for an unknown feed" do
    get feeds_info_path, params: { url: "https://unknown.test/feed.xml" }
    assert_response :not_found
  end
end
