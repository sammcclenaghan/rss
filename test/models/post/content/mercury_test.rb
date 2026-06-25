require "test_helper"

class Post::Content::MercuryTest < ActiveSupport::TestCase
  test "is disabled and returns nil when no extract url is configured" do
    mercury = Post::Content::Mercury.new(url: nil)

    assert_not mercury.enabled?
    assert_nil mercury.parse("https://example.com/a", "<p>body</p>")
  end

  test "returns nil for blank html without calling out" do
    mercury = Post::Content::Mercury.new(url: "http://extract.invalid/parse")

    assert mercury.enabled?
    assert_nil mercury.parse("https://example.com/a", "")
  end
end
