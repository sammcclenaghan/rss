require "net/http"
require "json"

class Post
  class Content
    # Thin client for the Mercury parser sidecar (see extract/, modelled on
    # github.com/feedbin/extract). Given a page URL and its HTML, returns the
    # extracted article body as an HTML string, or nil on any failure.
    #
    # The sidecar is a trusted internal host, so this is a plain POST — the
    # SSRF guarding happens earlier, when Post::Content::Extractor fetches the
    # page itself.
    class Mercury
      OPEN_TIMEOUT = 5
      READ_TIMEOUT = 20

      RESCUABLE = [
        JSON::ParserError, SocketError, SystemCallError,
        Net::OpenTimeout, Net::ReadTimeout, IOError, URI::InvalidURIError
      ].freeze

      def initialize(url: Rails.configuration.x.rss.extract_url,
                     token: Rails.configuration.x.rss.extract_token)
        @url = url
        @token = token
      end

      def enabled?
        @url.present?
      end

      # Returns the extracted article HTML, or nil when disabled or on failure.
      def parse(page_url, html)
        return unless enabled?
        return if html.blank?

        response = post(page_url, html)
        return unless response.is_a?(Net::HTTPSuccess)

        JSON.parse(response.body)["content"].presence
      rescue *RESCUABLE
        nil
      end

      private
        def post(page_url, html)
          uri = URI.parse(@url)
          request = Net::HTTP::Post.new(uri)
          request["Content-Type"] = "application/json"
          request["X-Extract-Token"] = @token if @token.present?
          request.body = JSON.generate(url: page_url, html: html)

          Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https",
            open_timeout: OPEN_TIMEOUT, read_timeout: READ_TIMEOUT) do |http|
            http.request(request)
          end
        end
    end
  end
end
