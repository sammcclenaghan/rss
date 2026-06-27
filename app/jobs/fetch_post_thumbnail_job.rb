class FetchPostThumbnailJob < ApplicationJob
  queue_as :default

  def perform(post, image_url = nil)
    Post::Thumbnail.new.fetch_and_store(post, image_url: image_url)
  end
end
