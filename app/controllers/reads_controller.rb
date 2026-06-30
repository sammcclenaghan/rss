# frozen_string_literal: true

class ReadsController < ApplicationController
  before_action :set_provider, only: :create_all

  # Mark a single post read (idempotent).
  def create
    ReadPost.find_or_create_by(post_id: params[:id])
    head :no_content
  end

  # Mark a single post unread.
  def destroy
    ReadPost.where(post_id: params[:id]).delete_all
    head :no_content
  end

  # Mark every unread post in the current view (all / tag / feed, honouring the
  # active search) as read, then return to where the request came from.
  def create_all
    ids = Post.for_feeds(scoped_feed_list.feed_ids).unread
    ids = ids.matching(params[:query]) if params[:query].present?
    ids = ids.pluck(:id)

    now = Time.current
    rows = ids.map { |post_id| { post_id: post_id, created_at: now, updated_at: now } }
    ReadPost.insert_all(rows, unique_by: :post_id) if rows.any?

    redirect_back fallback_location: root_path
  end

  private

  def set_provider
    @provider = Feed::Provider.from_app_config
  end

  def scoped_feed_list
    if params[:tag].present?
      @provider.for_tag(params[:tag])
    elsif params[:feed].present?
      @provider.for_url(params[:feed])
    else
      @provider.visible
    end
  end
end
