class RefreshOutdatedFeedsJob < ApplicationJob
  queue_as :default

  # Enqueues a RefreshFeedJob for every configured feed that is now outdated.
  # Run on a schedule (see config/recurring.yml) to keep feeds fresh in the
  # background, independent of anyone visiting the site.
  def perform
    Feed::Provider.from_app_config.all.reload_outdated
  end
end
