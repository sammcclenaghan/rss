# frozen_string_literal: true

require "resolv"
require "ipaddr"

module RestrictedHTTP
  class Violation < StandardError; end

  # Guards outbound HTTP against Server-Side Request Forgery. Resolves a
  # hostname to a single IP (so callers can pin the connection and defeat DNS
  # rebinding) and refuses any address on a private network.
  #
  # The name resolver is injectable so the guard can be exercised with a fake
  # resolver instead of real DNS.
  module PrivateNetworkGuard
    extend self

    LOCAL_IP = IPAddr.new("0.0.0.0/8") # "This" network

    # Returns a safe IP for the hostname, preferring IPv4 for reachability.
    # Raises Violation if it cannot be resolved or resolves to a private range.
    def resolve(hostname, resolver: Resolv)
      addresses = resolver.getaddresses(hostname)
      raise Violation, "Could not resolve #{hostname}" if addresses.empty?

      ip = addresses.min_by { |address| ipv4?(address) ? 0 : 1 }
      raise Violation, "Attempt to access private IP via #{hostname}" if private_ip?(ip)

      ip
    end

    def private_ip?(ip)
      IPAddr.new(ip).then do |ipaddr|
        ipaddr.private? || ipaddr.loopback? || ipaddr.link_local? ||
          ipaddr.ipv4_mapped? || ipaddr.ipv4_compat? || LOCAL_IP.include?(ipaddr)
      end
    rescue IPAddr::InvalidAddressError
      true
    end

    private

    def ipv4?(address)
      IPAddr.new(address).ipv4?
    rescue IPAddr::InvalidAddressError
      false
    end
  end
end
