require "test_helper"

class FeedsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @previous_config_file = Rails.configuration.x.rss.config_file
    # A writable copy so create/update/destroy can save without mutating the fixture.
    @config_file = Tempfile.new([ "feeds", ".txt" ])
    @config_file.write("https://xkcd.com/rss.xml XKCD[#abc] #comics\n")
    @config_file.flush
    Rails.configuration.x.rss.config_file = @config_file.path
  end

  teardown do
    Rails.configuration.x.rss.config_file = @previous_config_file
    @config_file.close!
  end

  def config_now
    Feed::Config.new.parse(File.read(@config_file.path))
  end

  test "returns feed metadata as json" do
    get feeds_info_path, params: { url: feeds(:xkcd).url }
    assert_response :success

    body = JSON.parse(response.body)
    assert_equal "XKCD", body["name"]
    assert_equal %w[#comics], body["tags"]
  end

  test "returns 404 for an unknown feed" do
    get feeds_info_path, params: { url: "https://unknown.test/feed.xml" }
    assert_response :not_found
  end

  test "index renders the manage page" do
    get feeds_path
    assert_response :success
    assert_select "h1", "Manage feeds"
  end

  test "create adds a feed to the config" do
    post feeds_path, params: { url: "https://new.example/feed.xml", name: "New Feed", tag: "Tech" }

    assert_redirected_to feeds_path
    assert config_now.include?("https://new.example/feed.xml")
    assert_equal "New Feed", config_now.name_for("https://new.example/feed.xml")
    assert_equal %w[#tech], config_now.tags_for("https://new.example/feed.xml")
  end

  test "create rejects a non-http url" do
    post feeds_path, params: { url: "ftp://bad.example/feed.xml", name: "Bad" }

    assert_redirected_to feeds_path
    assert_not config_now.include?("ftp://bad.example/feed.xml")
  end

  test "create rejects a duplicate url" do
    post feeds_path, params: { url: "https://xkcd.com/rss.xml", name: "Dup" }

    assert_redirected_to feeds_path
    assert_equal "XKCD", config_now.name_for("https://xkcd.com/rss.xml")
  end

  test "update edits a feed's presentation" do
    patch feed_path(feeds(:xkcd).id), params: { name: "XKCD Comics", tag: "fun", color: "#123456", hidden: "1" }

    assert_redirected_to feeds_path
    url = "https://xkcd.com/rss.xml"
    assert_equal "XKCD Comics", config_now.name_for(url)
    assert_equal %w[#fun], config_now.tags_for(url)
    assert config_now.hidden?(url)
  end

  test "destroy removes the feed from config and database" do
    feed = feeds(:xkcd)
    delete feed_path(feed.id)

    assert_redirected_to feeds_path
    assert_not config_now.include?("https://xkcd.com/rss.xml")
    assert_not Feed.exists?(feed.id)
  end

  test "export returns an opml document" do
    get feeds_export_path
    assert_response :success
    assert_includes response.body, "xmlUrl='https://xkcd.com/rss.xml'"
  end

  test "import adds feeds from an uploaded opml file" do
    opml = Tempfile.new([ "import", ".opml" ])
    opml.write(<<~OPML)
      <?xml version="1.0"?>
      <opml version="2.0"><body>
        <outline type="rss" text="Imported" xmlUrl="https://imported.example/feed.xml"/>
      </body></opml>
    OPML
    opml.flush

    post feeds_import_path, params: { file: Rack::Test::UploadedFile.new(opml.path, "text/xml") }

    assert_redirected_to feeds_path
    assert config_now.include?("https://imported.example/feed.xml")
  ensure
    opml.close!
  end
end
