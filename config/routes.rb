Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  get "/about", to: "about#show", as: :about

  get "/auth/:provider/callback", to: "sessions#create", as: :auth_callback
  get "/auth/failure", to: "sessions#failure", as: :auth_failure
  delete "/logout", to: "sessions#destroy", as: :logout

  # Apple Shortcuts → Rails webhook endpoint (Bearer token auth, no CSRF cookie needed)
  post "/webhooks/health_data", to: "webhooks#health_data", as: :webhooks_health_data

  # Settings: webhook token 表示 / 再生成
  get  "/settings",               to: "settings#show",            as: :settings
  post "/settings/webhook_token", to: "settings#regenerate_token", as: :regenerate_webhook_token

  # Defines the root path route ("/")
  root "home#index"
end
