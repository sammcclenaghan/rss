# frozen_string_literal: true

class Feeds::ImportsController < ApplicationController
  def create
    if params[:file].blank?
      redirect_to feeds_path, alert: "Choose an OPML file to import."
    else
      import_from params[:file]
    end
  end

  private

  def import_from(file)
    count = Feed::Config.from_app_config.import_opml(file.read)

    if count.zero?
      redirect_to feeds_path, alert: "No feeds found in that file."
    else
      redirect_to feeds_path, notice: "Imported #{count} #{'feed'.pluralize(count)}."
    end
  end
end
