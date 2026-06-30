# frozen_string_literal: true

require "uri"

class Feed < ApplicationRecord
  has_many :posts, dependent: :delete_all

  validates :url, presence: true, uniqueness: true, length: { maximum: 250 }

  scope :outdated, -> { where("last_fetched_at <= ?", outdated_before) }

  class << self
    def outdated_before
      Time.current.to_i - Rails.configuration.x.rss.feed_update_frequency.to_i
    end

    def discover_name_for(url)
      Feed::Fetcher.new.title(url).presence || name_from_url(url)
    end

    private

    def name_from_url(url)
      host = URI.parse(url).host.to_s.sub(/\Awww\./, "")
      label = host.split(".").first.to_s
      label.empty? ? url : label.tr("-_", "  ").split.map(&:capitalize).join(" ")
    rescue URI::InvalidURIError
      url
    end
  end

  def outdated?
    last_fetched_at <= self.class.outdated_before
  end

  def touch_accessed
    update_column(:last_accessed_at, Time.current.to_i)
  end

  def mark_fetched
    update!(last_fetched_at: Time.current.to_i)
  end
end
