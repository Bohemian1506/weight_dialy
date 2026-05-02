require "rails_helper"

RSpec.describe StepRecord, type: :model do
  describe "associations" do
    it "belongs to user" do
      association = described_class.reflect_on_association(:user)
      expect(association).not_to be_nil
      expect(association.macro).to eq(:belongs_to)
    end
  end

  describe "validations" do
    describe "recorded_on" do
      it "is invalid without recorded_on" do
        record = build(:step_record, recorded_on: nil)
        expect(record).not_to be_valid
      end

      it "is valid with recorded_on present" do
        record = build(:step_record, recorded_on: Date.new(2026, 5, 1))
        expect(record).to be_valid
      end
    end

    describe "steps numericality" do
      it "is invalid with a negative steps value" do
        record = build(:step_record, steps: -1)
        expect(record).not_to be_valid
      end

      it "is invalid with a non-integer steps value" do
        record = build(:step_record, steps: 1.5)
        expect(record).not_to be_valid
      end

      it "is valid with steps = 0" do
        record = build(:step_record, steps: 0)
        expect(record).to be_valid
      end
    end

    describe "distance_meters numericality" do
      it "is invalid with a negative distance_meters value" do
        record = build(:step_record, distance_meters: -1)
        expect(record).not_to be_valid
      end

      it "is invalid with a non-integer distance_meters value" do
        record = build(:step_record, distance_meters: 3.7)
        expect(record).not_to be_valid
      end

      it "is valid with distance_meters = 0" do
        record = build(:step_record, distance_meters: 0)
        expect(record).to be_valid
      end
    end

    describe "flights_climbed numericality" do
      it "is invalid with a negative flights_climbed value" do
        record = build(:step_record, flights_climbed: -1)
        expect(record).not_to be_valid
      end

      it "is invalid with a non-integer flights_climbed value" do
        record = build(:step_record, flights_climbed: 0.9)
        expect(record).not_to be_valid
      end

      it "is valid with flights_climbed = 0" do
        record = build(:step_record, flights_climbed: 0)
        expect(record).to be_valid
      end
    end

    describe "uniqueness of recorded_on scoped to user_id" do
      let(:user) { create(:user) }
      let(:other_user) { create(:user) }
      let(:date) { Date.new(2026, 5, 1) }

      before { create(:step_record, user: user, recorded_on: date) }

      it "is invalid when the same user already has a record on the same date" do
        duplicate = build(:step_record, user: user, recorded_on: date)
        expect(duplicate).not_to be_valid
      end

      it "is valid when a different user has a record on the same date" do
        other_record = build(:step_record, user: other_user, recorded_on: date)
        expect(other_record).to be_valid
      end
    end
  end

  describe "#estimated_kcal" do
    it "returns the rounded calorie estimate based on steps and flights_climbed" do
      # 8000 * 0.04 + 12 * 0.5 = 320.0 + 6.0 = 326.0 → 326
      record = build(:step_record, steps: 8000, flights_climbed: 12)
      expect(record.estimated_kcal).to eq(326)
    end

    it "returns 0 when steps and flights_climbed are both 0" do
      record = build(:step_record, steps: 0, flights_climbed: 0)
      expect(record.estimated_kcal).to eq(0)
    end

    it "rounds correctly for fractional results" do
      # 1 step * 0.04 + 1 flight * 0.5 = 0.04 + 0.5 = 0.54 → 1
      record = build(:step_record, steps: 1, flights_climbed: 1)
      expect(record.estimated_kcal).to eq(1)
    end
  end
end
