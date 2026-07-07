# frozen_string_literal: true

class Feed
  # An enumerable collection of ConfiguredFeed objects.
  class List
    include Enumerable

    def initialize(feeds = [])
      @feeds = feeds
    end

    def each(&) = @feeds.each(&)
    def size = @feeds.size
    alias length size

    def feed_ids
      map { |feed| feed.feed.id }
    end

    def mapped_by_id
      index_by { |feed| feed.feed.id }
    end

    def tags
      flat_map(&:tags).uniq.sort
    end

    # Enqueues a refresh for every outdated feed. Returns the number enqueued.
    # Called from the scheduled RefreshOutdatedFeedsJob — never on the request
    # path, where it used to pile duplicate jobs onto the queue.
    def reload_outdated
      select(&:outdated?).each { |feed| RefreshFeedJob.perform_later(feed.feed) }.size
    end

    def as_json(*)
      map(&:as_json)
    end
  end
end
