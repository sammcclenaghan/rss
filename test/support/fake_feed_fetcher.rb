# A fake feed fetcher returning a fixed set of posts, for driving
# Feed::Refresher without real HTTP.
class FakeFeedFetcher
  attr_reader :fetched

  def initialize(posts = [])
    @posts = posts
    @fetched = []
  end

  def fetch(feed)
    @fetched << feed
    @posts
  end
end
