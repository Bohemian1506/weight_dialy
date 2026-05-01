class StepRecord < ApplicationRecord
  belongs_to :user

  validates :recorded_on, presence: true
  validates :steps, :distance_meters, :flights_climbed,
            numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :recorded_on, uniqueness: { scope: :user_id }

  # Rough calorie estimate used for display only.
  # Formula: 1 step ≈ 0.04 kcal (flat walking), 1 flight of stairs ≈ 0.5 kcal.
  # METs-based calculation (accounting for body weight, speed, etc.) is a future enhancement.
  def estimated_kcal
    (steps * 0.04 + flights_climbed * 0.5).round
  end
end
