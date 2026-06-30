# frozen_string_literal: true

class Feeds::ExportsController < ApplicationController
  def show
    send_data Feed::Opml.export(Feed::Config.from_app_config),
              filename: "feeds.opml", type: "text/x-opml", disposition: "attachment"
  end
end
