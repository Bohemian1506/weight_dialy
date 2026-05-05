FactoryBot.define do
  factory :one_time_login_token do
    user
    sequence(:token) { |n| "test_token_#{n}_#{SecureRandom.hex(8)}" }
    expires_at { 30.seconds.from_now }
    used_at { nil }

    trait :expired do
      expires_at { 1.second.ago }
    end

    trait :used do
      used_at { 1.second.ago }
    end
  end
end
