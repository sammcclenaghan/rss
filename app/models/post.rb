class Post < ApplicationRecord
  include Pagination

  belongs_to :feed

  # Transient presentation metadata (the post's ConfiguredFeed), attached at
  # query time. Not persisted.
  attr_accessor :feed_config

  validates :guid, presence: true, uniqueness: { scope: :feed_id }
  validates :title, presence: true, length: { maximum: 250 }
  validates :url, presence: true, length: { maximum: 250 }

  scope :latest_first, -> { order(published_at: :desc) }
  scope :for_feeds, ->(feed_ids) { where(feed_id: feed_ids) }
  scope :published_before, ->(timestamp) { where(published_at: ...timestamp.to_i) }
  scope :matching, ->(query) {
    where("title LIKE :q OR description LIKE :q", q: "%#{sanitize_sql_like(query)}%")
  }

  def published_at_time
    Time.at(published_at)
  end

  def thumbnail?
    thumbnail.present?
  end
end
