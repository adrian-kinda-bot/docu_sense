require "sidekiq/web"

Rails.application.routes.draw do
  mount Sidekiq::Web => "/sidekiq" # access it at http://localhost:3000/sidekiq

  devise_for :users, class_name: Users::Models::User.name, controllers: {
    registrations: "users/registrations",
    sessions: "users/sessions"
  }

  # Root route
  get "/", to: "dashboard#index"
  root "dashboard#index"

  # Dashboard
  get "dashboard", to: "dashboard#index"

  # Document Collections
  resources :document_collections do
    resources :documents, only: [ :index, :new, :create ]
  end

  # Documents
  resources :documents, only: [ :show, :edit, :update, :destroy ] do
    member do
      patch :regenerate_embeddings
      get :regenerate_embeddings
    end
  end

  # Chat Sessions
  resources :chat_sessions, only: [ :index, :show, :new, :create, :update, :destroy ] do
    resources :chat_messages, only: [ :create ]
  end

  # Health check
  get "up" => "rails/health#show", as: :rails_health_check
end
