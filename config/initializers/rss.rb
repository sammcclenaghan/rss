# Configuration for the RSS reader, tunable via environment variables.
Rails.application.configure do
  config.x.rss.tap do |rss|
    # How long (in seconds) before a feed is considered outdated and refreshed.
    rss.feed_update_frequency = Integer(ENV.fetch("FEED_UPDATE_FREQUENCY_MINUTES", 60)) * 60

    # Whether to fetch and store post thumbnails (og:image) in the background.
    rss.load_post_thumbnails = ENV.fetch("LOAD_POST_THUMBNAILS", "true") == "true"

    # Number of days of posts to retain when pruning. Blank disables pruning.
    rss.prune_posts_after_days = ENV["PRUNE_POSTS_AFTER_DAYS"].presence&.to_i

    # Number of posts shown per page.
    rss.posts_per_page = Integer(ENV.fetch("POSTS_PER_PAGE", 100))

    # Path to the feeds configuration file.
    rss.config_file = ENV.fetch("RSS_CONFIG_FILE", Rails.root.join("config/feeds.txt").to_s)
  end
end
