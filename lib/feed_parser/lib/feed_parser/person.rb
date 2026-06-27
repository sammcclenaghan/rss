# frozen_string_literal: true

module FeedParser
  Person = Data.define(:name, :email, :uri) do
    def initialize(name: nil, email: nil, uri: nil)
      super
    end
  end
end
