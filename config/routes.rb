Rails.application.routes.draw do
  get 'home/index'
  get 'orders/index'
  get 'profile/show'
  post '/analyze_image', to: 'image_analysis#analyze'
  devise_for :users

  resources :tests
  resources :profiles
  resources :orders do
    collection do
      get :accepted_orders
      get :pick_up_orders
    end
    member do
      patch :confirm
      patch :progress
    end
  end
  resources :clothings

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html
  root to: "home#index"
  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Defines the root path route ("/")
  # root "posts#index"
end
