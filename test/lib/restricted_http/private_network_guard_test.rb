require "test_helper"
require "restricted_http/private_network_guard"

class RestrictedHTTP::PrivateNetworkGuardTest < ActiveSupport::TestCase
  Guard = RestrictedHTTP::PrivateNetworkGuard

  test "flags loopback, private, link-local, and 'this' network addresses" do
    assert Guard.private_ip?("127.0.0.1")
    assert Guard.private_ip?("10.0.0.1")
    assert Guard.private_ip?("192.168.1.1")
    assert Guard.private_ip?("169.254.169.254") # cloud metadata endpoint
    assert Guard.private_ip?("0.0.0.0")
  end

  test "allows public addresses" do
    assert_not Guard.private_ip?("1.1.1.1")
    assert_not Guard.private_ip?("8.8.8.8")
  end

  test "treats unparseable addresses as private" do
    assert Guard.private_ip?("not-an-ip")
  end

  test "resolve returns a public address" do
    resolver = FakeNameResolver.new("example.com" => "93.184.216.34")
    assert_equal "93.184.216.34", Guard.resolve("example.com", resolver: resolver)
  end

  test "resolve prefers IPv4 for reachability" do
    resolver = FakeNameResolver.new("example.com" => [ "2606:2800:220::1", "93.184.216.34" ])
    assert_equal "93.184.216.34", Guard.resolve("example.com", resolver: resolver)
  end

  test "resolve raises when the address is private" do
    resolver = FakeNameResolver.new("evil.test" => "127.0.0.1")
    assert_raises(RestrictedHTTP::Violation) { Guard.resolve("evil.test", resolver: resolver) }
  end

  test "resolve raises when the hostname cannot be resolved" do
    resolver = FakeNameResolver.new
    assert_raises(RestrictedHTTP::Violation) { Guard.resolve("nowhere.test", resolver: resolver) }
  end
end
