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

  desc "Re-fetch every feed to backfill post content (content:encoded / <content>)"
  task backfill_content: :environment do
    total = Feed.count
    missing_before = Post.where.missing(:content).count
    count = 0

    puts "Backfill content refresh starting..."
    puts "  feeds: #{total}"
    puts "  posts missing content before enqueue: #{missing_before}"

    Feed.find_each.with_index(1) do |feed, index|
      RefreshFeedJob.perform_later(feed)
      count += 1
      puts "  [#{index}/#{total}] enqueued RefreshFeedJob feed_id=#{feed.id} url=#{feed.url}"
    end

    puts "Backfill content refresh enqueued #{count} feed(s)."
    puts "Watch worker logs for Feed::Refresher progress. Re-check with: bin/rails runner 'puts Post.where.missing(:content).count'"
  end

  desc "Extract full article content for every post that is still missing it"
  task extract_missing_content: :environment do
    unless Rails.configuration.x.rss.extract_url.present?
      abort "EXTRACT_URL is not set — start the extraction sidecar first (see extract/)."
    end

    count = 0
    Post.where.missing(:content).find_each do |post|
      ExtractPostContentJob.perform_later(post)
      count += 1
    end
    puts "Enqueued extraction for #{count} post(s) missing content."
  end

  desc "Fetch and parse a feed URL without saving (rss:test_feed[URL])"
  task :test_feed, [ :url ] => :environment do |_task, args|
    abort "Usage: bin/rails rss:test_feed[https://example.com/feed.xml]" if args[:url].blank?

    posts = Feed::Fetcher.new.fetch(Feed.new(url: args[:url]))

    if posts.empty?
      abort "No posts fetched. The feed could not be reached or was not valid."
    end

    puts "Found #{posts.size} post(s):"
    posts.each { |post| puts "  [#{post.url}] #{post.title}" }
  end
end
