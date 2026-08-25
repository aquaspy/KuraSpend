Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  get  "signup", to: "registrations#new", as: :signup
  post "signup", to: "registrations#create"
  get  "login", to: "sessions#new", as: :login
  post "login", to: "sessions#create"
  delete "logout", to: "sessions#destroy", as: :logout

  get  "unlock", to: "locks#show", as: :unlock
  post "unlock", to: "locks#create"
  post "lock", to: "locks#lock", as: :lock
  post "auto_lock", to: "locks#toggle_auto_lock", as: :auto_lock
  resource :password, only: %i[edit update]

  get  "export", to: "months#export", as: :export
  post "import", to: "months#import", as: :import
  patch "settings", to: "settings#update", as: :settings

  resources :expenses, only: %i[create update destroy]
  resources :subscriptions, only: %i[create update destroy]
  resources :payment_days, only: %i[create update destroy]

  get ":year/:month", to: "months#show", as: :month,
    constraints: { year: /\d{4}/, month: /\d{1,2}/ }
  root "months#show"
end
