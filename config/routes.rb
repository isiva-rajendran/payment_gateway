Rails.application.routes.draw do
  devise_for :users
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  root "subscriptions#index"

  # Subscription routes
  resources :subscriptions, only: [:index, :new, :create, :destroy] do
    collection do
      get 'success'
      get 'cancel'
    end
  end

  # Dashboard routes
  namespace :dashboard do
    get 'index'
    get 'payment_history'
    get 'subscription_details'
  end

  # Webhook routes
  post '/webhooks/paypal', to: 'webhooks#paypal'
  
  # Direct routes for convenience
  get 'dashboard', to: 'dashboard#index'
  get 'payment_history', to: 'dashboard#payment_history'
  get 'subscription_details', to: 'dashboard#subscription_details'
end
