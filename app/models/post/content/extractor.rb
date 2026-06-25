require "restricted_http/client"

class Post
  class Content
    # Turns an article URL into clean, sanitized reader HTML: fetches the page
    # with the SSRF-guarded client, hands the HTML to the Mercury sidecar for
    # readability extraction, then runs the result through ContentFilters.
    #
    # Both collaborators are injectable so this can be driven without a network
    # in tests.
    class Extractor
      USER_AGENT = "rss-reader/1.0"
      MAX_PAGE_SIZE = 5.megabytes

      def initialize(http: default_http, mercury: Mercury.new)
        @http = http
        @mercury = mercury
      end

      def enabled?
        @mercury.enabled?
      end

      # Returns sanitized article HTML, or nil if the page could not be fetched
      # or extracted.
      def extract(url)
        return unless enabled?

        page = @http.get(url)
        return unless page&.ok?
        return unless page.content_type.to_s.include?("html")

        article = @mercury.parse(url, page.body)
        return if article.blank?

        ContentFilters::ArticleContent.apply(article, base_url: url).presence
      end

      private
        def default_http
          RestrictedHTTP::Client.new(user_agent: USER_AGENT, max_body_size: MAX_PAGE_SIZE)
        end
    end
  end
end
