# frozen_string_literal: true

require "restricted_http/response"

# A fake HTTP client that returns canned RestrictedHTTP::Response objects
# keyed by URL. A real, working stand-in for RestrictedHTTP::Client — not a
# stub or mock.
class FakeHTTPClient
  def initialize(responses = {})
    @responses = {}
    responses.each { |url, response| stub(url, **response) }
  end

  # Register a response for a URL.
  def stub(url, status: 200, body: "", content_type: "text/html")
    @responses[url.to_s] = RestrictedHTTP::Response.new(
      status: status, body: body, content_type: content_type
    )
    self
  end

  # Returns the canned response for the URL, or nil (mirroring a failed fetch).
  def get(url)
    @responses[url.to_s]
  end
end
