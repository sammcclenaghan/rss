# frozen_string_literal: true

ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

# Load test support files (fakes, helpers).
Dir[Rails.root.join("test/support/**/*.rb")].each { |file| require file }

module ActiveSupport
  class TestCase
    include ActiveJob::TestHelper

    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    private

    # Reads a fixture file from test/fixtures/files.
    def file_fixture_content(name)
      file_fixture(name).read
    end

    # Temporarily points the RSS config file at a given path, restoring it after.
    def with_config_file(path)
      rss = Rails.configuration.x.rss
      previous = rss.config_file
      rss.config_file = path
      yield
    ensure
      rss.config_file = previous
    end
  end
end
