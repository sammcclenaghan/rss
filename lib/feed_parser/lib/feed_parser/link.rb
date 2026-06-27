# frozen_string_literal: true

module FeedParser
  Link = Data.define(:href, :rel, :type, :hreflang, :title, :length) do
    def initialize(href:, rel: nil, type: nil, hreflang: nil, title: nil, length: nil)
      super
    end
  end
end
