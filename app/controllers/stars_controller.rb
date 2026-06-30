# frozen_string_literal: true

class StarsController < ApplicationController
  # Star a single post (idempotent).
  def create
    StarredPost.find_or_create_by(post_id: params[:id])
    head :no_content
  end

  # Unstar a single post.
  def destroy
    StarredPost.where(post_id: params[:id]).delete_all
    head :no_content
  end
end
