# frozen_string_literal: true

require "test_helper"

class Post
  class ThumbnailTest < ActiveSupport::TestCase
    setup do
      @post = feeds(:basecamp).posts.create!(
        title: "Thumbnail Target",
        url: "https://example.com/thumbnail-target",
        guid: "thumbnail-target-#{SecureRandom.hex(4)}",
        description: "Body",
        published_at: Time.current.to_i
      )
    end

    teardown do
      file = Rails.root.join("public/storage", @post.reload.thumbnail)
      file.delete if @post.thumbnail.present? && file.exist?
    end

    test "discovers the og:image, downloads it, and stores a thumbnail" do
      client = FakeHTTPClient.new
                             .stub(@post.url, body: og_image_page("https://cdn.test/image.png"))
                             .stub("https://cdn.test/image.png", body: png_bytes, content_type: "image/png")

      assert Post::Thumbnail.new(client: client).fetch_and_store(@post)
      assert @post.reload.thumbnail.end_with?(".png")
      assert Rails.root.join("public/storage", @post.thumbnail).exist?
    end

    test "downloads a feed-provided image url directly" do
      client = FakeHTTPClient.new
                             .stub("https://cdn.test/feed-image.png", body: png_bytes, content_type: "image/png")

      assert Post::Thumbnail.new(client: client).fetch_and_store(@post, image_url: "https://cdn.test/feed-image.png")
      assert @post.reload.thumbnail.end_with?(".png")
      assert Rails.root.join("public/storage", @post.thumbnail).exist?
    end

    test "returns false when the page has no og:image" do
      client = FakeHTTPClient.new.stub(@post.url, body: "<html><head></head></html>")
      assert_not Post::Thumbnail.new(client: client).fetch_and_store(@post)
    end

    test "returns false when the downloaded resource is not an image" do
      client = FakeHTTPClient.new
                             .stub(@post.url, body: og_image_page("https://cdn.test/not-image"))
                             .stub("https://cdn.test/not-image", body: "totally not an image", content_type: "text/plain")

      assert_not Post::Thumbnail.new(client: client).fetch_and_store(@post)
    end

    test "returns false when the page cannot be fetched" do
      assert_not Post::Thumbnail.new(client: FakeHTTPClient.new).fetch_and_store(@post)
    end

    private

    def og_image_page(image_url)
      %(<html><head><meta property="og:image" content="#{image_url}"></head></html>)
    end

    # Minimal valid PNG header so Marcel detects image/png.
    def png_bytes
      "\x89PNG\r\n\x1a\n".b + ("\x00" * 32).b
    end
  end
end
