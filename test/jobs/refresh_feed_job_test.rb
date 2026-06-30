# frozen_string_literal: true

require "test_helper"

class RefreshFeedJobTest < ActiveSupport::TestCase
  test "is enqueued for a feed" do
    assert_enqueued_with(job: RefreshFeedJob, args: [ feeds(:xkcd) ]) do
      RefreshFeedJob.perform_later(feeds(:xkcd))
    end
  end
end
