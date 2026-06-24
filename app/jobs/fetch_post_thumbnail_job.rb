class FetchPostThumbnailJob < ApplicationJob
  queue_as :default

  def perform(post)
    Post::Thumbnail.new.fetch_and_store(post)
  end
end
