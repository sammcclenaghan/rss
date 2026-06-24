module ApplicationHelper
  # Mirrors the reference app's `timestampToRelativeTime` (resources/js/util.js)
  # so post timestamps read identically — e.g. "2 days", "1 hour", "3 weeks".
  # The view wraps the result as "About <time> ago".
  RELATIVE_TIME_FORMATS = [
    { limit: 45, label: "second", div: 60 },
    { limit: 50, label: "minute", div: 60 },
    { limit: 22, label: "hour", div: 24 },
    { limit: 6, label: "day", div: 7 },
    { limit: 51, label: "week", div: 52 },
    { limit: 10_000, label: "year", div: 1 }
  ].freeze

  def relative_published_time(timestamp)
    count = (Time.now.to_i - timestamp).abs
    label = RELATIVE_TIME_FORMATS.first[:label]

    RELATIVE_TIME_FORMATS.each do |format|
      label = format[:label]
      break if count < format[:limit]

      count = count.to_f / format[:div]
    end

    int = count.round
    "#{int} #{label}#{int == 1 ? '' : 's'}"
  end

  # Path the search form submits to. Scoped to the current tag/feed view (or
  # the homepage), matching the reference app's per-view search.
  def search_scope_path
    if @tag.present?
      tag_posts_path(@tag)
    elsif @selected_feed.present?
      feed_posts_path(Feed::Config.encode_feed_url(@selected_feed))
    else
      root_path
    end
  end

  # Current path with the unread filter toggled on or off, preserving the
  # active tag/feed scope (in the path) and search query (in the params).
  def unread_filter_path(enable:)
    query = request.query_parameters.except("page", "unread")
    query["unread"] = "1" if enable
    query.empty? ? request.path : "#{request.path}?#{query.to_query}"
  end

  # Clamps a feed's configured colour to a lightness range that stays legible
  # on both the dark (gray-900) and light (gray-50) backgrounds. Near-black
  # values like "#000000" would otherwise vanish in dark mode. Non-hex colours
  # (CSS names) are returned unchanged.
  def legible_feed_color(color)
    rgb = hex_to_rgb(color)
    return color unless rgb

    h, s, l = rgb_to_hsl(*rgb)
    "hsl(#{h.round}, #{(s * 100).round}%, #{(l.clamp(0.5, 0.8) * 100).round}%)"
  end

  private
    def hex_to_rgb(color)
      hex = color.to_s.delete_prefix("#")
      hex = hex.chars.map { |c| c * 2 }.join if hex.length == 3
      return nil unless hex.match?(/\A[0-9a-fA-F]{6}\z/)

      [ hex[0, 2], hex[2, 2], hex[4, 2] ].map { |pair| pair.to_i(16) }
    end

    def rgb_to_hsl(red, green, blue)
      r, g, b = red / 255.0, green / 255.0, blue / 255.0
      max, min = [ r, g, b ].minmax.reverse
      lightness = (max + min) / 2.0
      return [ 0.0, 0.0, lightness ] if max == min

      delta = max - min
      saturation = lightness > 0.5 ? delta / (2 - max - min) : delta / (max + min)
      hue =
        case max
        when r then (g - b) / delta + (g < b ? 6 : 0)
        when g then (b - r) / delta + 2
        else (r - g) / delta + 4
        end

      [ hue * 60, saturation, lightness ]
    end
end
