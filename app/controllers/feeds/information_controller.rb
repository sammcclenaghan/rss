# frozen_string_literal: true

class Feeds::InformationController < ApplicationController
  def show
    feed = Feed::Provider.from_app_config.get(params[:url])

    if feed
      render json: feed
    else
      head :not_found
    end
  end
end
