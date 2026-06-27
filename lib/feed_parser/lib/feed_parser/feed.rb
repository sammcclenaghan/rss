# frozen_string_literal: true

module FeedParser
  EMPTY_ARRAY = [].freeze unless const_defined?(:EMPTY_ARRAY)

  Feed = Data.define(
    :id,
    :title,
    :description,
    :url,
    :feed_url,
    :image,
    :updated,
    :authors,
    :categories,
    :links,
    :entries
  ) do
    def initialize(id: nil, title: nil, description: nil, url: nil, feed_url: nil,
                   image: nil, updated: nil, authors: EMPTY_ARRAY, categories: EMPTY_ARRAY,
                   links: EMPTY_ARRAY, entries: EMPTY_ARRAY)
      super
    end
  end
end
