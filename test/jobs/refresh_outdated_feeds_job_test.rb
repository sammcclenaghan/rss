require "test_helper"

class RefreshOutdatedFeedsJobTest < ActiveSupport::TestCase
  setup do
    @previous_config_file = Rails.configuration.x.rss.config_file
    Rails.configuration.x.rss.config_file = file_fixture("feeds.txt").to_s
  end

  teardown { Rails.configuration.x.rss.config_file = @previous_config_file }

  test "enqueues a refresh for each outdated configured feed" do
    feeds(:xkcd).update!(last_fetched_at: 0)

    assert_enqueued_with(job: RefreshFeedJob) do
      RefreshOutdatedFeedsJob.perform_now
    end
  end

  test "does not enqueue refreshes when no feed is outdated" do
    feeds(:xkcd).update!(last_fetched_at: Time.current.to_i)

    assert_no_enqueued_jobs only: RefreshFeedJob do
      RefreshOutdatedFeedsJob.perform_now
    end
  end
end
