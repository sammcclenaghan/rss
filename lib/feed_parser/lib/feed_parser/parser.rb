# frozen_string_literal: true

require_relative "parser/atom"

module FeedParser
  module Parser
    PARSERS = [Atom].freeze

    module_function

    def parse(xml)
      parser = PARSERS.find { |candidate| candidate.able_to_parse?(xml) }
      raise ParseError, "unsupported feed format" unless parser

      parser.parse(xml)
    end
  end
end
