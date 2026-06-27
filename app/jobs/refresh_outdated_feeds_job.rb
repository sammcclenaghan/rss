class RefreshOutdatedFeedsJob < ApplicationJob
  queue_as :default

  # Enqueues a RefreshFeedJob for every configured feed that is now outdated.
  # Run on a schedule (see config/recurring.yml) to keep feeds fresh in the
  # background, independent of anyone visiting the site.
  def perform
    # Skip the request-path auto-fetch; reload_outdated already covers
    # brand-new feeds (last_fetched_at = 0 is considered outdated).
    Feed::Provider.from_app_config(refresh_new_feeds: false).all.reload_outdated
  end
end
