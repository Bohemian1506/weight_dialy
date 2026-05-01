Rails.application.config.middleware.use OmniAuth::Builder do
  provider :google_oauth2,
           Rails.application.credentials.dig(:google, :client_id) || ENV["GOOGLE_CLIENT_ID"],
           Rails.application.credentials.dig(:google, :client_secret) || ENV["GOOGLE_CLIENT_SECRET"],
           {
             scope: "email,profile",
             prompt: "select_account",
             image_aspect_ratio: "square",
             image_size: 200
           }
end

OmniAuth.config.allowed_request_methods = [ :post ]
