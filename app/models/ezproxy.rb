# frozen_string_literal: true

require "uri"

# Rewrites an outbound article link to route through a library EZProxy host, so a
# user with institutional access lands on the authenticated copy of a subscribed
# site (e.g. The Economist via UVic). The proxy host is configured per-feed, so
# only feeds the user opts in for are affected.
#
# Presentation only: the stored Post#url is never modified, and the app never
# fetches through the proxy — it's login-gated, so authentication happens in the
# user's browser when they click the link.
class Ezproxy
  # Returns the EZProxy-rewritten URL for `host`, or the original url when no
  # host is configured or the url can't be parsed.
  def self.rewrite(url, host:)
    return url if host.blank?

    uri = URI.parse(url.to_s)
    return url unless uri.host

    uri.host = "#{mangle(uri.host)}.#{host}"
    uri.to_s
  rescue URI::InvalidURIError
    url
  end

  # EZProxy host-mangling: escape existing dashes (- -> --) then turn dots into
  # dashes. "www.economist.com" -> "www-economist-com".
  def self.mangle(host)
    host.downcase.gsub("-", "--").tr(".", "-")
  end
end
