# frozen_string_literal: true

module FeedParser
  Entry = Data.define(
    :id,
    :title,
    :url,
    :summary,
    :content,
    :published,
    :updated,
    :authors,
    :links,
  ) do
    def initialize(id: nil, title: nil, url: nil, summary: nil, content: nil,
                   published: nil, updated: nil, authors: EMPTY_ARRAY, links: EMPTY_ARRAY)
      super
    end
  end
end
