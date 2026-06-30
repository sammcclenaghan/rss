# frozen_string_literal: true

class Posts::StarsController < ApplicationController
  def create
    Post.find(params[:post_id]).star
    head :no_content
  end

  def destroy
    Post.find(params[:post_id]).unstar
    head :no_content
  end
end
