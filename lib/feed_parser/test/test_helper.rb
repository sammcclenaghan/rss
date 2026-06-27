# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)

require "minitest/autorun"
require "feed_parser"
require_relative "support/fixtures"

class Minitest::Test
  include FixtureHelpers
end
