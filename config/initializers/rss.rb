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

    # Path to the feeds configuration file. In production this points at a
    # volume-backed path (RSS_CONFIG_FILE=/rails/storage/feeds.txt) so feeds
    # added through the UI survive redeploys; in development it defaults to the
    # repo's config/feeds.txt.
    bundled_feeds = Rails.root.join("config/feeds.txt").to_s
    rss.config_file = ENV.fetch("RSS_CONFIG_FILE", bundled_feeds)

    # First-boot seeding: when the configured file lives somewhere other than
    # the bundled default (i.e. a fresh volume) and doesn't exist yet, seed it
    # from the bundled feed list so a new deployment starts with the defaults
    # and is immediately editable.
    if rss.config_file != bundled_feeds && !File.exist?(rss.config_file) && File.exist?(bundled_feeds)
      require "fileutils"
      FileUtils.mkdir_p(File.dirname(rss.config_file))
      FileUtils.cp(bundled_feeds, rss.config_file)
    end
  end
end
