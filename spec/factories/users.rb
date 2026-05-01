FactoryBot.define do
  factory :user do
    sequence(:uid) { |n| "uid_#{n}" }
    provider { "google_oauth2" }
    sequence(:email) { |n| "user#{n}@example.com" }
    sequence(:name) { |n| "Test User #{n}" }
    # 固定 URL で十分。画像取得テストは model spec の from_omniauth で行う
    image_url { "https://example.com/photo.jpg" }
  end
end
