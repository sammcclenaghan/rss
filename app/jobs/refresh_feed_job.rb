# frozen_string_literal: true

class RefreshFeedJob < ApplicationJob
  queue_as :default

  def perform(feed)
    Feed::Refresher.new.refresh(feed)
  end
end
