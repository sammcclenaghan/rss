# frozen_string_literal: true

Rails.application.routes.draw do
  mount RailsIcons::Engine, at: "/rails_icons"
  root "posts#index"

  namespace :feeds do
    resource :information, only: :show
    resource :export, only: :show, controller: :exports
    resource :import, only: :create, controller: :imports
  end

  resources :feeds, only: %i[index create update destroy]

  resource :settings, only: :show

  # Post listing with filters
  get "tag/:tag", to: "posts#tag", as: :tag_posts
  get "feed/*feed", to: "posts#feed", as: :feed_posts, format: false

  resources :posts, only: [] do
    resource :reading, module: :posts, only: %i[create destroy]
    resource :star, module: :posts, only: %i[create destroy]
  end

  namespace :posts do
    resource :bulk_reading, only: :create
  end

  # Background job dashboard (Solid Queue)
  mount MissionControl::Jobs::Engine, at: "/jobs"

  # Health check
  get "up" => "rails/health#show", as: :rails_health_check
end
