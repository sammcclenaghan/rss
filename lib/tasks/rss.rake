# frozen_string_literal: true

namespace :rss do
  desc "Trigger a refresh of all outdated feeds"
  task update_outdated_feeds: :environment do
    count = Feed::Provider.from_app_config.all.reload_outdated
    puts "Triggered refresh for #{count} outdated feed(s)."
  end

  desc "Prune posts older than PRUNE_POSTS_AFTER_DAYS (or pass days=N)"
  task :prune_posts, [ :days ] => :environment do |_task, args|
    days = (args[:days] || Rails.configuration.x.rss.prune_posts_after_days).to_i

    if days <= 0
      puts "No retention configured. Set PRUNE_POSTS_AFTER_DAYS or pass days=N."
    else
      deleted = Post::Pruner.new.prune(days)
      puts "Deleted #{deleted} post(s) older than #{days} day(s)."
    end
  end

  desc "Fetch and parse a feed URL without saving (rss:test_feed[URL])"
  task :test_feed, [ :url ] => :environment do |_task, args|
    abort "Usage: bin/rails rss:test_feed[https://example.com/feed.xml]" if args[:url].blank?

    posts = Feed::Fetcher.new.fetch(Feed.new(url: args[:url]))

    abort "No posts fetched. The feed could not be reached or was not valid." if posts.empty?

    puts "Found #{posts.size} post(s):"
    posts.each { |post| puts "  [#{post.url}] #{post.title}" }
  end
end
