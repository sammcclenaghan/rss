# frozen_string_literal: true

Gem::Specification.new do |spec|
  spec.name = "feed_parser"
  spec.version = "0.1.0"
  spec.summary = "Fast Ruby RSS/Atom feed parser"
  spec.authors = [ "feed_parser contributors" ]
  spec.files = Dir["lib/**/*.rb"]
  spec.require_paths = [ "lib" ]
  spec.required_ruby_version = ">= 3.2"
end
