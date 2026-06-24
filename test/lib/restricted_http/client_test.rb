require "test_helper"
require "restricted_http/client"

# Narrow integration test for the real client against a real in-process HTTP
# server. A fake address resolver points the client at the loopback server.
class RestrictedHTTP::ClientTest < ActiveSupport::TestCase
  setup do
    @server = TestHTTPServer.new
    @resolver = FakeAddressResolver.new(@server.host => @server.host)
    @client = RestrictedHTTP::Client.new(user_agent: "test", resolver: @resolver)
  end

  teardown { @server.shutdown }

  test "performs a GET and returns a Response" do
    @server.on("/feed", body: "<rss/>", headers: { "Content-Type" => "application/xml" })

    response = @client.get(@server.url_for("/feed"))
    assert response.ok?
    assert_equal "<rss/>", response.body
    assert_equal "application/xml", response.content_type
  end

  test "returns a non-ok Response for error statuses" do
    @server.on("/missing", status: 404)

    response = @client.get(@server.url_for("/missing"))
    assert_not response.ok?
    assert_equal 404, response.status
  end

  test "follows redirects" do
    @server.on("/start", status: 302, headers: { "Location" => "/final" })
    @server.on("/final", body: "arrived")

    assert_equal "arrived", @client.get(@server.url_for("/start")).body
  end

  test "gives up after too many redirects" do
    @server.on("/loop", status: 302, headers: { "Location" => "/loop" })
    assert_nil @client.get(@server.url_for("/loop"))
  end

  test "refuses bodies larger than the limit" do
    @server.on("/big", body: "x" * 2_000)
    client = RestrictedHTTP::Client.new(user_agent: "test", max_body_size: 1_000, resolver: @resolver)

    assert_nil client.get(@server.url_for("/big"))
  end

  test "returns nil when the guard refuses the address" do
    client = RestrictedHTTP::Client.new(user_agent: "test") # real guard
    assert_nil client.get("http://127.0.0.1/anything")
  end
end
