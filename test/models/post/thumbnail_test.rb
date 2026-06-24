require "test_helper"

class Post::ThumbnailTest < ActiveSupport::TestCase
  setup { @post = posts(:basecamp_post) }

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
