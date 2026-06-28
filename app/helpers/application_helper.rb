module ApplicationHelper
  # A post's publish date as YYYY/M/D (e.g. "2025/6/10"), matching the Fusion
  # reference app's compact date format.
  def post_date(timestamp)
    Time.at(timestamp).strftime("%Y/%-m/%-d")
  end

  # The heading for the current content view: the selected feed or tag, the
  # active filter when there's no scope, or "All Posts" on the homepage.
  def current_view_title
    if @selected_feed.present? && @display_feeds.length == 1
      @display_feeds.first.name
    elsif @tag.present?
      @tag.capitalize
    elsif @starred_only
      "Starred"
    elsif @unread_only
      "Unread"
    else
      "All Posts"
    end
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

  # Path for the All / Unread / Starred content tabs. Preserves the current
  # tag/feed scope (the request path) and search query, swapping only the
  # mutually-exclusive unread/starred filter. `filter` is :all, :unread, or
  # :starred.
  def filter_path(filter)
    query = request.query_parameters.except("page", "unread", "starred")
    query["unread"] = "1" if filter == :unread
    query["starred"] = "1" if filter == :starred
    query.empty? ? request.path : "#{request.path}?#{query.to_query}"
  end

  # Whether a given content tab (:all / :unread / :starred) is the active one.
  def filter_active?(filter)
    case filter
    when :unread  then @unread_only
    when :starred then @starred_only
    else !@unread_only && !@starred_only
    end
  end

  # Classes for one segment of the All / Unread / Starred content tab control.
  def content_tab_class(filter)
    base = "rounded-md px-3 py-1 transition-colors"
    state =
      if filter_active?(filter)
        "bg-white dark:bg-gray-700 font-semibold text-black dark:text-gray-100 shadow-sm"
      else
        "text-gray-600 dark:text-gray-400 hover:text-black dark:hover:text-gray-200"
      end
    "#{base} #{state}"
  end

  # Classes for a top-level sidebar nav row (Unread / Starred / All), with an
  # active state that matches the highlighted feed rows.
  def sidebar_nav_class(active)
    base = "flex items-center gap-2.5 rounded-md px-2 py-1.5 text-sm font-medium transition-colors"
    state =
      if active
        "bg-gray-200 text-black dark:bg-gray-800 dark:text-gray-100"
      else
        "text-gray-600 dark:text-gray-400 hover:bg-gray-100 dark:hover:bg-gray-800 hover:text-black dark:hover:text-gray-200"
      end
    "#{base} #{state}"
  end

  # Groups configured feeds into sidebar folders by tag. Untagged feeds fall
  # into a "Default" folder (placed first); each tagged feed appears under every
  # tag it carries. Tag folders are ordered most-used-first (ties broken
  # alphabetically), mirroring the sidebar's previous Tags ordering. Returns an
  # array of { name:, tag:, feeds:, unread: } hashes; `tag` is nil for Default.
  def grouped_feeds(feed_list, unread_counts = {})
    default = []
    by_tag = Hash.new { |h, k| h[k] = [] }
    tag_counts = Hash.new(0)

    feed_list.each do |feed|
      tags = feed.tags.map { |tag| tag.delete_prefix("#") }.reject(&:blank?).uniq
      if tags.empty?
        default << feed
      else
        tags.each do |tag|
          by_tag[tag] << feed
          tag_counts[tag] += 1
        end
      end
    end

    ordered_tags = by_tag.keys.sort_by { |tag| [ -tag_counts[tag], tag ] }

    groups = ordered_tags.map do |tag|
      feeds = by_tag[tag]
      { name: tag, tag: tag, feeds: feeds, unread: folder_unread(feeds, unread_counts) }
    end

    if default.any?
      groups.unshift(
        { name: "Default", tag: nil, feeds: default, unread: folder_unread(default, unread_counts) }
      )
    end

    groups
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
    def folder_unread(feeds, unread_counts)
      feeds.sum { |feed| unread_counts.fetch(feed.feed.id, 0).to_i }
    end

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
