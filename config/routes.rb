Rails.application.routes.draw do
  root "posts#index"

  # Feed info JSON endpoint
  get "feeds/info", to: "feeds#show"

  # Post listing with filters
  get "tag/:tag", to: "posts#tag", as: :tag_posts
  get "feed/*feed", to: "posts#feed", as: :feed_posts, format: false

  # Health check
  get "up" => "rails/health#show", as: :rails_health_check
end
