# frozen_string_literal: true

class PrunePostsJob < ApplicationJob
  queue_as :default

  # Deletes posts older than the configured retention window. No-op unless
  # PRUNE_POSTS_AFTER_DAYS is set. Run on a schedule (see config/recurring.yml).
  def perform
    days = Rails.configuration.x.rss.prune_posts_after_days.to_i
    return if days <= 0

    Post::Pruner.new.prune(days)
  end
end
