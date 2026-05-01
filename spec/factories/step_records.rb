FactoryBot.define do
  factory :step_record do
    association :user
    sequence(:recorded_on) { |n| Date.new(2026, 1, 1) + n.days }
    steps { 8000 }
    distance_meters { 5000 }
    flights_climbed { 12 }
  end
end
