# Google OAuth の Client ID/Secret は本番では config/credentials.yml.enc を一次情報とし、
# 未設定なら ENV にフォールバックする。開発環境では credentials を空のままにして .env から読む。
# 本番で両方未設定の場合はファイル末尾のバリデーションで起動時に検出する。

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

if Rails.env.production?
  client_id = Rails.application.credentials.dig(:google, :client_id) || ENV["GOOGLE_CLIENT_ID"]
  client_secret = Rails.application.credentials.dig(:google, :client_secret) || ENV["GOOGLE_CLIENT_SECRET"]

  if client_id.blank? || client_secret.blank?
    raise "Google OAuth credentials が未設定です " \
          "(config/credentials.yml.enc の :google.client_id / :client_secret か、" \
          "環境変数 GOOGLE_CLIENT_ID / GOOGLE_CLIENT_SECRET のいずれかで設定してください)"
  end
end
