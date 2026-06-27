# frozen_string_literal: true

require_relative 'feed_parser/link'
require_relative 'feed_parser/person'
require_relative 'feed_parser/category'
require_relative 'feed_parser/feed'
require_relative 'feed_parser/entry'
require_relative 'feed_parser/parser'

module FeedParser
  class ParseError < StandardError; end

  module_function

  def parse(xml)
    Parser.parse(xml)
  end
end
