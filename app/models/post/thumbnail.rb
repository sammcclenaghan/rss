require "restricted_http/client"
require "digest"
require "marcel"

class Post
  # Fetches a post's Open Graph image and stores it as a local thumbnail.
  # The HTTP client is injectable.
  class Thumbnail
    USER_AGENT = "rss-reader/1.0"
    MAX_PAGE_SIZE = 2.megabytes
    OG_IMAGE = /<meta[^<>]*property=["']og:image["'][^<>]*>/i
    CONTENT_URL = /content=["'](.*?)["']/i

    def initialize(client: default_client)
      @client = client
    end

    # Fetches and stores the thumbnail for a post. Returns true on success.
    # When the feed provides an image URL we can download it directly; otherwise
    # fall back to fetching the article page and reading its Open Graph image.
    def fetch_and_store(post, image_url: nil)
      image_url = image_url.presence || discover_image_url(post.url)
      return false if image_url.blank?

      image = download_image(image_url)
      return false if image.nil?

      store(post, image)
      true
    end

    private
      def default_client
        RestrictedHTTP::Client.new(user_agent: USER_AGENT, max_body_size: MAX_PAGE_SIZE)
      end

      def discover_image_url(page_url)
        response = @client.get(page_url)
        return unless response&.ok?

        meta = response.body.match(OG_IMAGE) or return
        content = meta[0].match(CONTENT_URL) or return

        url = CGI.unescapeHTML(content[1])
        url if url.match?(%r{\Ahttps?://})
      end

      def download_image(url)
        response = @client.get(url)
        return unless response&.ok?

        content_type = Marcel::MimeType.for(StringIO.new(response.body))
        return unless content_type.start_with?("image/")

        { data: response.body, extension: content_type.split("/").last }
      end

      def store(post, image)
        fingerprint = Digest::SHA256.hexdigest(post.guid.to_s)[0, 8]
        path = "thumbs/#{post.feed_id}/#{post.id}-#{fingerprint}.#{image[:extension]}"
        destination = Rails.root.join("public/storage", path)

        destination.dirname.mkpath
        destination.binwrite(image[:data])

        post.update!(thumbnail: path)
      end
  end
end
