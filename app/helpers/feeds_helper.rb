# frozen_string_literal: true

module FeedsHelper
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
    groups = ordered_tags.map { |tag| feed_group(tag, by_tag[tag], unread_counts) }
    groups.unshift(feed_group("Default", default, unread_counts, tag: nil)) if default.any?
    groups
  end

  def legible_feed_color(color)
    rgb = hex_to_rgb(color)
    return color unless rgb

    h, s, l = rgb_to_hsl(*rgb)
    "hsl(#{h.round}, #{(s * 100).round}%, #{(l.clamp(0.5, 0.8) * 100).round}%)"
  end

  private

  def feed_group(name, feeds, unread_counts, tag: name)
    { name: name, tag: tag, feeds: feeds, unread: folder_unread(feeds, unread_counts) }
  end

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
    r = red / 255.0
    g = green / 255.0
    b = blue / 255.0
    max, min = [ r, g, b ].minmax.reverse
    lightness = (max + min) / 2.0
    return [ 0.0, 0.0, lightness ] if max == min

    rgb_delta_to_hsl(max, min, lightness, r: r, g: g, b: b)
  end

  def rgb_delta_to_hsl(max, min, lightness, r:, g:, b:)
    delta = max - min
    saturation = lightness > 0.5 ? delta / (2 - max - min) : delta / (max + min)
    hue = hue_from_rgb_delta(max, delta, r: r, g: g, b: b)

    [ hue * 60, saturation, lightness ]
  end

  def hue_from_rgb_delta(max, delta, r:, g:, b:)
    case max
    when r then (g - b) / delta + (g < b ? 6 : 0)
    when g then (b - r) / delta + 2
    else (r - g) / delta + 4
    end
  end
end
