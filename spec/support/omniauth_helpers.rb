# OmniAuth テストモードの有効化と認証ハッシュ生成ヘルパー
#
# OmniAuth はデフォルトで GET /auth/:provider/callback への直アクセスを
# 禁止しているため、テストモードに切り替えてモックデータを差し込む。
# 使い方:
#   before { mock_google_oauth2(uid: "123", email: "test@example.com") }
#   get auth_callback_path(provider: "google_oauth2")
#
# テストが終わったら after で reset_omniauth_mocks を呼ぶか、
# 後述の after ブロックに委ねる (rails_helper.rb 側でリセット済み)。

OmniAuth.config.test_mode = true

module OmniauthHelpers
  # Google OAuth2 モック認証ハッシュをアプリの env にセットする。
  # request spec では Rails.application.env_config に直接差し込む方式が確実。
  def mock_google_oauth2(uid: "default_uid", email: "user@example.com", name: "Test User", image: "https://example.com/photo.jpg")
    auth_hash = OmniAuth::AuthHash.new(
      provider: "google_oauth2",
      uid: uid,
      info: OmniAuth::AuthHash::InfoHash.new(
        email: email,
        name: name,
        image: image
      )
    )
    OmniAuth.config.mock_auth[:google_oauth2] = auth_hash
    # request spec は Rack env を直接触れないため env_config 経由でセットする
    Rails.application.env_config["omniauth.auth"] = auth_hash
  end

  def reset_omniauth_mocks
    OmniAuth.config.mock_auth[:google_oauth2] = nil
    Rails.application.env_config.delete("omniauth.auth")
  end
end

RSpec.configure do |config|
  config.include OmniauthHelpers, type: :request

  config.after(:each, type: :request) do
    reset_omniauth_mocks
  end
end
