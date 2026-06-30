# frozen_string_literal: true

Rails.application.routes.draw do
  mount RailsIcons::Engine, at: "/rails_icons"
  root "posts#index"

  # Feed info JSON endpoint (used by the sidebar reload poller)
  get "feeds/info", to: "feeds#show"

  # Feed management (add / edit / remove) and OPML import/export.
  get  "feeds/export", to: "feeds#export", as: :feeds_export
  post "feeds/import", to: "feeds#import", as: :feeds_import
  resources :feeds, only: %i[index create update destroy]

  # Settings (appearance + read-only behaviour config)
  get "settings", to: "settings#show"

  # Post listing with filters
  get "tag/:tag", to: "posts#tag", as: :tag_posts
  get "feed/*feed", to: "posts#feed", as: :feed_posts, format: false

  # Read/unread state
  post "posts/read_all", to: "reads#create_all", as: :read_all_posts
  post "posts/:id/read", to: "reads#create", as: :post_read
  delete "posts/:id/read", to: "reads#destroy"

  # Starred state
  post "posts/:id/star", to: "stars#create", as: :post_star
  delete "posts/:id/star", to: "stars#destroy"

  # Background job dashboard (Solid Queue)
  mount MissionControl::Jobs::Engine, at: "/jobs"

  # Health check
  get "up" => "rails/health#show", as: :rails_health_check
end
