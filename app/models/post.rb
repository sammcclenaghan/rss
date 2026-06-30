# frozen_string_literal: true

class Post < ApplicationRecord
  include Pagination

  belongs_to :feed
  has_one :read_post, dependent: :delete
  has_one :starred_post, dependent: :delete

  # Transient presentation metadata (the post's ConfiguredFeed), attached at
  # query time. Not persisted.
  attr_accessor :feed_config

  # Transient image URL discovered from the feed itself. Feed::Refresher passes
  # this to thumbnail fetching so we can avoid fetching the article page just to
  # discover an Open Graph image when RSS/Atom already supplied one.
  attr_accessor :feed_image_url

  # Transient read flag, batch-loaded by Post::Fetcher to avoid per-post
  # queries. nil means "not loaded"; `read?` then falls back to a lookup.
  attr_accessor :read_state

  # Transient starred flag, batch-loaded by Post::Fetcher (mirrors read_state).
  attr_accessor :starred_state

  validates :guid, presence: true, uniqueness: { scope: :feed_id }
  validates :title, presence: true, length: { maximum: 250 }
  validates :url, presence: true, length: { maximum: 250 }

  scope :latest_first, -> { order(published_at: :desc) }
  scope :for_feeds, ->(feed_ids) { where(feed_id: feed_ids) }
  scope :published_before, ->(timestamp) { where(published_at: ...timestamp.to_i) }
  scope :matching, lambda { |query|
    where("title LIKE :q OR description LIKE :q", q: "%#{sanitize_sql_like(query)}%")
  }
  scope :read, -> { where(id: ReadPost.select(:post_id)) }
  scope :unread, -> { where.not(id: ReadPost.select(:post_id)) }
  scope :starred, -> { where(id: StarredPost.select(:post_id)) }

  def read?
    read_state.nil? ? read_post.present? : read_state
  end

  def starred?
    starred_state.nil? ? starred_post.present? : starred_state
  end

  def published_at_time
    Time.at(published_at)
  end

  def thumbnail?
    thumbnail.present?
  end
end
