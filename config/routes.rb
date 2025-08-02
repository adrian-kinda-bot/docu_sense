Rails.application.routes.draw do
  devise_for :users, controllers: {
    registrations: "users/registrations",
    sessions: "users/sessions"
  }

  # Root route
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
    end
  end

  # Chat Sessions
  resources :chat_sessions, only: [ :index, :show, :new, :create, :destroy ] do
    resources :chat_messages, only: [ :create ]
  end

  # Health check
  get "up" => "rails/health#show", as: :rails_health_check
end
