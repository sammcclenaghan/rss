require "test_helper"

class Post::Content::ExtractorTest < ActiveSupport::TestCase
  FakePage = Struct.new(:status, :body, :content_type, keyword_init: true) do
    def ok? = status.between?(200, 299)
  end

  class FakeHttp
    def initialize(page) = @page = page
    def get(_url) = @page
  end

  class FakeMercury
    def initialize(content:, enabled: true)
      @content = content
      @enabled = enabled
    end

    def enabled? = @enabled
    def parse(_url, _html) = @content
  end

  def extractor(page:, content:, mercury_enabled: true)
    Post::Content::Extractor.new(
      http: FakeHttp.new(page),
      mercury: FakeMercury.new(content: content, enabled: mercury_enabled)
    )
  end

  def html_page(body)
    FakePage.new(status: 200, body: body, content_type: "text/html; charset=utf-8")
  end

  test "extracts, fixes relative urls, and sanitizes the article" do
    page = html_page("<html><body>raw</body></html>")
    raw_article = %(<p>Hi <a href="/rel">link</a><script>x()</script></p>)

    result = extractor(page: page, content: raw_article).extract("https://example.com/posts/a")

    assert_includes result, "https://example.com/rel"
    assert_not_includes result, "script"
    assert_includes result, "Hi"
  end

  test "returns nil when extraction is disabled" do
    page = html_page("<p>body</p>")
    assert_nil extractor(page: page, content: "<p>x</p>", mercury_enabled: false).extract("https://example.com/a")
  end

  test "returns nil when the page cannot be fetched" do
    assert_nil extractor(page: nil, content: "<p>x</p>").extract("https://example.com/a")
  end

  test "skips non-html responses" do
    pdf = FakePage.new(status: 200, body: "%PDF-1.7", content_type: "application/pdf")
    assert_nil extractor(page: pdf, content: "<p>x</p>").extract("https://example.com/a.pdf")
  end

  test "returns nil when mercury extracts nothing" do
    page = html_page("<p>body</p>")
    assert_nil extractor(page: page, content: nil).extract("https://example.com/a")
  end
end
