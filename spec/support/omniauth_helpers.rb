# OmniAuth テストモード関連のヘルパー
#
# OmniAuth はデフォルトで GET /auth/:provider/callback への直アクセスを
# 禁止しているため、テストモードに切り替えてモックデータを差し込む。
# 使い方:
#   before { mock_google_oauth2(uid: "123", email: "test@example.com") }
#   get auth_callback_path(provider: "google_oauth2")
#
# test_mode のグローバル副作用を避けるため、有効化は RSpec.configure 内で行う
# (トップレベルで設定すると model spec など全 spec に副作用が及ぶため)。

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
  config.before(:suite) do
    OmniAuth.config.test_mode = true
  end

  config.include OmniauthHelpers, type: :request

  config.after(:each, type: :request) do
    reset_omniauth_mocks
  end
end
