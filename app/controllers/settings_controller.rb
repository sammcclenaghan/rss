# frozen_string_literal: true

class SettingsController < ApplicationController
  # Appearance (client-side theme) plus a read-only view of the feed-behaviour
  # settings, which are configured via environment variables at boot.
  def show
    @rss = Rails.configuration.x.rss
    @feed_count = Feed::Config.from_app_config.feed_urls.size
  end
end
