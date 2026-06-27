# frozen_string_literal: true

module FixtureHelpers
  FIXTURE_ROOT = File.expand_path("../fixtures", __dir__)

  def fixture_path(relative_path)
    File.join(FIXTURE_ROOT, relative_path)
  end

  def fixture_data(relative_path)
    File.binread(fixture_path(relative_path))
  end

  def parse_fixture(relative_path)
    FeedParser.parse(fixture_data(relative_path))
  end
end
