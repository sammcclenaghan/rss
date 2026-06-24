class Feed
  # An enumerable collection of ConfiguredFeed objects.
  class List
    include Enumerable

    def initialize(feeds = [])
      @feeds = feeds
    end

    def each(&) = @feeds.each(&)
    def size = @feeds.size
    alias_method :length, :size

    def feed_ids
      map { |feed| feed.feed.id }
    end

    def mapped_by_id
      index_by { |feed| feed.feed.id }
    end

    def tags
      flat_map(&:tags).uniq.sort
    end

    # Triggers a refresh for every outdated feed. Returns the number refreshed.
    def reload_outdated
      select(&:outdated?).each(&:start_reloading).size
    end

    def as_json(*)
      map(&:as_json)
    end
  end
end
