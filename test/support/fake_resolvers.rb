# A fake DNS resolver responding to #getaddresses, for exercising
# RestrictedHTTP::PrivateNetworkGuard without touching real DNS.
class FakeNameResolver
  def initialize(addresses_by_host = {})
    @addresses_by_host = addresses_by_host
  end

  def getaddresses(hostname)
    Array(@addresses_by_host[hostname])
  end
end

# A fake address resolver responding to #resolve(host) -> ip, for injecting
# into RestrictedHTTP::Client so it connects to a known address (e.g. a local
# test server) without consulting the private-network guard.
class FakeAddressResolver
  def initialize(ip_by_host = {})
    @ip_by_host = ip_by_host
  end

  def resolve(hostname)
    @ip_by_host.fetch(hostname, hostname)
  end
end
