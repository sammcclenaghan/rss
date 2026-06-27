# frozen_string_literal: true

require_relative "feed_parser/atom"
require_relative "feed_parser/feed"
require_relative "feed_parser/entry"

module FeedParser
  class ParseError < StandardError; end

  module_function

  def parse(xml)
    Atom.parse(xml)
  end
end
