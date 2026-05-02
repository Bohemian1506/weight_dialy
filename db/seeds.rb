# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

# 開発環境のみ: 最初の User に 30 日分の StepRecord を投入する。
# idempotent: find_or_create / exists? でスキップ済みデータは触らない。
if Rails.env.development?
  user = User.first
  if user
    rest_days = [ 3, 9, 17, 24 ]  # インデックス 0 = 今日

    30.times do |i|
      date = i.days.ago.to_date
      next if user.step_records.exists?(recorded_on: date)
      next if rest_days.include?(i)

      user.step_records.create!(
        recorded_on:      date,
        steps:            rand(5_000..9_000),
        distance_meters:  rand(3_000..7_000),
        flights_climbed:  rand(5..18)
      )
    end

    puts "Seeded #{user.step_records.count} step_records for #{user.name}"
  else
    puts "No user found — skipping step_records seed. Log in with Google first."
  end
end
