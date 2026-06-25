class ExtractPostContentJob < ApplicationJob
  queue_as :default

  def perform(post)
    body = Post::Content::Extractor.new.extract(post.url)
    Post::Content.capture(post, body, source: Post::Content::EXTRACTED)
  end
end
