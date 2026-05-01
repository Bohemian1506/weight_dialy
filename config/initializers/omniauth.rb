Rails.application.config.middleware.use OmniAuth::Builder do
  provider :google_oauth2,
           ENV["GOOGLE_CLIENT_ID"],
           ENV["GOOGLE_CLIENT_SECRET"],
           {
             scope: "email,profile",
             prompt: "select_account",
             image_aspect_ratio: "square",
             image_size: 200
           }
end

OmniAuth.config.allowed_request_methods = [:post]
OmniAuth.config.silence_get_warning = true
