# frozen_string_literal: true

module FeedParser
  Entry = Data.define(
    :id,
    :title,
    :url,
    :summary,
    :content,
    :image,
    :published,
    :updated,
    :authors,
    :categories,
    :links,
  ) do
    def initialize(id: nil, title: nil, url: nil, summary: nil, content: nil,
                   image: nil, published: nil, updated: nil, authors: EMPTY_ARRAY,
                   categories: EMPTY_ARRAY, links: EMPTY_ARRAY)
      super
    end
  end
end
