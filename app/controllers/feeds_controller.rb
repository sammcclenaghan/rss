# frozen_string_literal: true

require "uri"

class FeedsController < ApplicationController
  before_action :load_config, only: %i[create update destroy import]

  # JSON feed info used by the sidebar reload poller.
  def show
    feed = Feed::Provider.from_app_config.get(params[:url])

    if feed
      render json: feed
    else
      head :not_found
    end
  end

  # Manage Feeds page: every configured feed, grouped into folders by the view.
  def index
    @provider = Feed::Provider.from_app_config
    @feeds = @provider.all
  end

  # Add a feed by URL. Name is auto-discovered from the feed when left blank.
  def create
    url = params[:url].to_s.strip
    return redirect_to(feeds_path, alert: "Enter a feed URL.") if url.blank?
    return redirect_to(feeds_path, alert: "The URL must start with http:// or https://") unless valid_url?(url)
    return redirect_to(feeds_path, alert: "That feed is already in your list.") if @config.include?(url)

    name = params[:name].to_s.strip.presence || discover_name(url)
    @config.prepend(url, name: name, tags: normalize_tags(params[:tag]),
                         color: params[:color].to_s.strip, hidden: params[:hidden] == "1",
                         proxy: normalize_proxy(params[:proxy]))
    @config.save!

    refresh_provider
    redirect_to feeds_path, notice: "Added #{name}."
  end

  # Edit a feed's presentation (name / group / colour / hidden). The URL is the
  # feed's identity and isn't editable here.
  def update
    feed = Feed.find(params[:id])
    name = params[:name].to_s.strip.presence || feed.url
    @config.add(feed.url, name: name, tags: normalize_tags(params[:tag]),
                          color: params[:color].to_s.strip, hidden: params[:hidden] == "1",
                          proxy: normalize_proxy(params[:proxy]))
    @config.save!

    redirect_to feeds_path, notice: "Updated #{name}."
  end

  # Remove a feed: drop it from the config and delete its posts + read/star
  # state so nothing is orphaned.
  def destroy
    feed = Feed.find(params[:id])
    @config.remove(feed.url)
    @config.save!

    post_ids = feed.posts.ids
    feed.destroy
    ReadPost.where(post_id: post_ids).delete_all
    StarredPost.where(post_id: post_ids).delete_all

    redirect_to feeds_path, notice: "Removed feed."
  end

  # Download the current feed list as OPML.
  def export
    config = Feed::Config.from_app_config
    send_data Feed::Opml.export(config),
              filename: "feeds.opml", type: "text/x-opml", disposition: "attachment"
  end

  # Bulk-add feeds from an uploaded OPML file.
  def import
    file = params[:file]
    return redirect_to(feeds_path, alert: "Choose an OPML file to import.") if file.blank?

    count = Feed::Opml.import(file.read, into: @config)
    if count.zero?
      redirect_to feeds_path, alert: "No feeds found in that file."
    else
      @config.save!
      refresh_provider
      redirect_to feeds_path, notice: "Imported #{count} #{'feed'.pluralize(count)}."
    end
  end

  private

  def load_config
    @config = Feed::Config.from_app_config
  end

  # Rebuilds the provider so newly-configured feeds get a DB record and an
  # initial refresh enqueued.
  def refresh_provider
    Feed::Provider.from_app_config
  end

  def valid_url?(url)
    url.match?(%r{\Ahttps?://}i)
  end

  # An optional library EZProxy host for routing this feed's article links
  # through institutional access. Accepts a bare host or a pasted URL; we keep
  # just the host (no scheme, no path), and strip any leading "login." so the
  # host-mangled article URL resolves rather than hitting the login endpoint.
  def normalize_proxy(proxy)
    host = proxy.to_s.strip.sub(%r{\Ahttps?://}i, "").split("/").first.to_s
    host.delete_prefix("login.")
  end

  # A single group field becomes one "#tag"; blank means the Default folder.
  def normalize_tags(group)
    tag = group.to_s.strip.delete_prefix("#").downcase.gsub(/\s+/, "-")
    tag.blank? ? [] : [ "##{tag}" ]
  end

  # Auto-name a feed: prefer its channel title, fall back to the host.
  def discover_name(url)
    Feed::Fetcher.new.title(url).presence || name_from_host(url)
  end

  def name_from_host(url)
    host = URI.parse(url).host.to_s.sub(/\Awww\./, "")
    label = host.split(".").first.to_s
    label.empty? ? url : label.tr("-_", "  ").split.map(&:capitalize).join(" ")
  rescue URI::InvalidURIError
    url
  end
end
