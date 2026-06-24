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
end
