# frozen_string_literal: true

require "net/http"
require "restricted_http/private_network_guard"
require "restricted_http/response"

module RestrictedHTTP
  # An HTTP client that pins connections to a guard-approved IP (defeating DNS
  # rebinding and private-network access), follows a bounded number of
  # redirects, and reads at most max_body_size bytes.
  #
  # The address resolver is injectable: anything responding to
  # `resolve(host) -> ip`. It defaults to PrivateNetworkGuard.
  class Client
    DEFAULT_MAX_BODY_SIZE = 5.megabytes
    MAX_REDIRECTS = 5
    OPEN_TIMEOUT = 10
    READ_TIMEOUT = 10

    RESCUABLE = [
      Violation, SocketError, SystemCallError,
      Net::OpenTimeout, Net::ReadTimeout, Net::HTTPBadResponse,
      OpenSSL::SSL::SSLError, URI::InvalidURIError
    ].freeze

    def initialize(user_agent:, max_body_size: DEFAULT_MAX_BODY_SIZE, resolver: PrivateNetworkGuard)
      @user_agent = user_agent
      @max_body_size = max_body_size
      @resolver = resolver
    end

    # Performs a guarded GET. Returns a Response, or nil on any failure
    # (guard violation, too many redirects, oversized body, network error).
    def get(url)
      follow(normalize(url), MAX_REDIRECTS)
    rescue *RESCUABLE
      nil
    end

    private

    def follow(url, redirects_left)
      return nil if redirects_left.negative?

      ip = @resolver.resolve(url.host)

      Net::HTTP.start(url.host, url.port, ipaddr: ip, use_ssl: url.scheme == "https",
                                          open_timeout: OPEN_TIMEOUT, read_timeout: READ_TIMEOUT) do |http|
        request = Net::HTTP::Get.new(url)
        request["User-Agent"] = @user_agent

        http.request(request) do |response|
          return handle(response, url, redirects_left)
        end
      end
    end

    def handle(response, url, redirects_left)
      if response.is_a?(Net::HTTPRedirection)
        location = url.merge(response["location"].to_s)
        return nil unless location.is_a?(URI::HTTP)

        follow(location, redirects_left - 1)
      else
        body = read_limited_body(response)
        return nil if body.nil?

        Response.new(status: response.code.to_i, body: body, content_type: response.content_type)
      end
    end

    # Reads the body in chunks, bailing (nil) if it exceeds max_body_size.
    def read_limited_body(response)
      StringIO.new.tap do |buffer|
        response.read_body do |chunk|
          return nil if buffer.size + chunk.bytesize > @max_body_size

          buffer << chunk
        end
      end.string
    end

    def normalize(url)
      url.is_a?(URI) ? url : URI.parse(url)
    end
  end
end
