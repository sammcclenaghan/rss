# frozen_string_literal: true

class Posts::BulkReadingsController < ApplicationController
  def create
    Post.mark_read_in(Feed::Provider.from_app_config.list_for(tag: params[:tag], url: params[:feed]), query: params[:query])
    redirect_back fallback_location: root_path
  end
end
