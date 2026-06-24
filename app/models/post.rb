class Post < ApplicationRecord
  include Pagination

  belongs_to :feed
  has_one :read_post, dependent: :delete

  # Transient presentation metadata (the post's ConfiguredFeed), attached at
  # query time. Not persisted.
  attr_accessor :feed_config

  # Transient read flag, batch-loaded by Post::Fetcher to avoid per-post
  # queries. nil means "not loaded"; `read?` then falls back to a lookup.
  attr_accessor :read_state

  validates :guid, presence: true, uniqueness: { scope: :feed_id }
  validates :title, presence: true, length: { maximum: 250 }
  validates :url, presence: true, length: { maximum: 250 }

  scope :latest_first, -> { order(published_at: :desc) }
  scope :for_feeds, ->(feed_ids) { where(feed_id: feed_ids) }
  scope :published_before, ->(timestamp) { where(published_at: ...timestamp.to_i) }
  scope :matching, ->(query) {
    where("title LIKE :q OR description LIKE :q", q: "%#{sanitize_sql_like(query)}%")
  }
  scope :read, -> { where(id: ReadPost.select(:post_id)) }
  scope :unread, -> { where.not(id: ReadPost.select(:post_id)) }

  def read?
    read_state.nil? ? read_post.present? : read_state
  end

  def published_at_time
    Time.at(published_at)
  end

  def thumbnail?
    thumbnail.present?
  end
end
