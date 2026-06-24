Rails.application.routes.draw do
  root "posts#index"

  # Feed info JSON endpoint
  get "feeds/info", to: "feeds#show"

  # Post listing with filters
  get "tag/:tag", to: "posts#tag", as: :tag_posts
  get "feed/*feed", to: "posts#feed", as: :feed_posts, format: false

  # Read/unread state
  post "posts/read_all", to: "reads#create_all", as: :read_all_posts
  post "posts/:id/read", to: "reads#create", as: :post_read
  delete "posts/:id/read", to: "reads#destroy"

  # Health check
  get "up" => "rails/health#show", as: :rails_health_check
end
