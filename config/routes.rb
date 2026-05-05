Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  get "/about", to: "about#show", as: :about

  get "/privacy", to: "legal#privacy", as: :privacy
  get "/terms",   to: "legal#terms",   as: :terms

  get "/auth/:provider/callback", to: "sessions#create", as: :auth_callback
  get "/auth/failure", to: "sessions#failure", as: :auth_failure
  # Phase 3 Capacitor OAuth ブリッジ: Custom Tabs から GET で開いて session フラグ立て + /auth/google_oauth2 へ自動 POST 中継
  get "/auth/capacitor_start", to: "sessions#capacitor_start", as: :capacitor_oauth_start
  # Phase 3 Capacitor OAuth ブリッジ: WebView 側で one-time token を消費して WebView cookie storage に session 確立
  get "/auto_login", to: "sessions#auto_login", as: :auto_login
  delete "/logout", to: "sessions#destroy", as: :logout

  # Apple Shortcuts → Rails webhook endpoint (Bearer token auth, no CSRF cookie needed)
  post "/webhooks/health_data", to: "webhooks#health_data", as: :webhooks_health_data

  # Settings: webhook token 表示 / 再生成
  get  "/settings",               to: "settings#show",            as: :settings
  post "/settings/webhook_token", to: "settings#regenerate_token", as: :regenerate_webhook_token

  # Account deletion (退会)
  delete "/account", to: "account/deletions#destroy", as: :account_deletion

  # Defines the root path route ("/")
  root "home#index"
end
