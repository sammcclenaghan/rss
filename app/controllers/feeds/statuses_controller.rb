# frozen_string_literal: true

class Feeds::StatusesController < ApplicationController
  # Refresh progress for the sidebar's single poller: which configured feeds
  # are still waiting on a background fetch. Deliberately read-only — the old
  # per-feed pollers went through Feed::Provider and wrote last_accessed_at
  # on every poll, contending with the refresh jobs for SQLite's write lock.
  def show
    urls = Feed::Config.from_app_config.feed_urls

    render json: { outdated_feed_ids: Feed.where(url: urls).outdated.pluck(:id) }
  end
end
