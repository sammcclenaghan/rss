# frozen_string_literal: true

class Posts::ReadingsController < ApplicationController
  def create
    Post.find(params[:post_id]).mark_read
    head :no_content
  end

  def destroy
    Post.find(params[:post_id]).mark_unread
    head :no_content
  end
end
