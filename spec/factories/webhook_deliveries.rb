FactoryBot.define do
  factory :webhook_delivery do
    association :user
    status { "success" }
    payload { { "records" => [] } }
    received_at { Time.current }
  end
end
