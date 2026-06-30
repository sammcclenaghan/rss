# frozen_string_literal: true

class FeedsController < ApplicationController
  rescue_from Feed::Config::BlankUrl, with: :blank_url
  rescue_from Feed::Config::InvalidUrl, with: :invalid_url
  rescue_from Feed::Config::DuplicateUrl, with: :duplicate_url

  # Manage Feeds page: every configured feed, grouped into folders by the view.
  def index
    @provider = Feed::Provider.from_app_config
    @feeds = @provider.all
  end

  # Add a feed by URL. Name is auto-discovered from the feed when left blank.
  def create
    name = Feed::Config.from_app_config.add_feed(**feed_config_params)
    redirect_to feeds_path, notice: "Added #{name}."
  end

  # Edit a feed's presentation (name / group / colour / hidden). The URL is the
  # feed's identity and isn't editable here.
  def update
    name = Feed::Config.from_app_config.update_feed(Feed.find(params[:id]), **feed_config_params)
    redirect_to feeds_path, notice: "Updated #{name}."
  end

  # Remove a feed from the config and database.
  def destroy
    Feed::Config.from_app_config.remove_feed(Feed.find(params[:id]))
    redirect_to feeds_path, notice: "Removed feed."
  end

  private

  def feed_config_params
    params.permit(:url, :name, :tag, :color, :hidden, :proxy).to_h.symbolize_keys
  end

  def blank_url
    redirect_to feeds_path, alert: "Enter a feed URL."
  end

  def invalid_url
    redirect_to feeds_path, alert: "The URL must start with http:// or https://"
  end

  def duplicate_url
    redirect_to feeds_path, alert: "That feed is already in your list."
  end
end
