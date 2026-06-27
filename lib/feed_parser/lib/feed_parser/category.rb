# frozen_string_literal: true

module FeedParser
  Category = Data.define(:term, :scheme, :label) do
    def initialize(term:, scheme: nil, label: nil)
      super
    end
  end
end
