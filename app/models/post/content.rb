class Post
  # Full, sanitized article HTML. Kept in its own table so the hot `posts`
  # table that backs list queries never loads it.
  #
  # `source` records where the body came from: "feed" (publisher's
  # content:encoded / Atom <content>, captured during refresh) or "extracted"
  # (readability scrape of the article page).
  class Content < ApplicationRecord
    self.table_name = "post_contents"

    FEED = "feed".freeze
    EXTRACTED = "extracted".freeze

    belongs_to :post

    # Stores a sanitized body for the post, filling or upgrading existing
    # content. Never replaces stored content with a shorter body, so a
    # truncated feed never clobbers a fuller extracted article. Returns the
    # record (which may be unchanged), or nil when there is nothing to store.
    def self.capture(post, body, source:)
      return if body.blank?

      record = post.content || post.build_content
      return record if record.body == body
      return record if record.persisted? && body.length < record.body.to_s.length

      record.update!(body: body, source: source, word_count: count_words(body))
      record
    end

    def self.count_words(html)
      ActionController::Base.helpers.strip_tags(html).split.size
    end
  end
end
