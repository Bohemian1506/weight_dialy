require "rails_helper"

RSpec.describe CalorieSavingsService do
  # DemoDataService::DemoRecord は recorded_on / steps / distance_meters / flights_climbed を持つ Struct
  # (= duck type で StepRecord と互換)。トップレベル定数化すると streak spec と衝突するため直接参照する。

  let(:today)         { Date.current }
  let(:this_month_15) { today.beginning_of_month + 14.days }
  let(:last_month_15) { (today - 1.month).beginning_of_month + 14.days }
  let(:two_months_ago_day) { (today - 2.months).beginning_of_month + 4.days }

  def build_record(date, steps)
    DemoDataService::DemoRecord.new(date, steps, 0, 0)
  end

  describe ".call" do
    context "空配列" do
      it "全 0 のハッシュを返す" do
        expect(CalorieSavingsService.call([])).to eq(this_month: 0, last_month: 0, total: 0)
      end
    end

    context "今月のみ 1 件 (1000 歩)" do
      let(:records) { [ build_record(this_month_15, 1000) ] }

      it "this_month = 40 kcal (= 1000 * 0.04)" do
        expect(CalorieSavingsService.call(records)[:this_month]).to eq(40)
      end

      it "last_month = 0 kcal" do
        expect(CalorieSavingsService.call(records)[:last_month]).to eq(0)
      end

      it "total = 40 kcal (= this_month と一致)" do
        expect(CalorieSavingsService.call(records)[:total]).to eq(40)
      end
    end

    context "前月のみ 1 件 (5000 歩)" do
      let(:records) { [ build_record(last_month_15, 5000) ] }

      it "this_month = 0 kcal" do
        expect(CalorieSavingsService.call(records)[:this_month]).to eq(0)
      end

      it "last_month = 200 kcal (= 5000 * 0.04)" do
        expect(CalorieSavingsService.call(records)[:last_month]).to eq(200)
      end

      it "total = 200 kcal" do
        expect(CalorieSavingsService.call(records)[:total]).to eq(200)
      end
    end

    context "今月 + 前月 + 2 ヶ月前 の混在" do
      let(:records) do
        [
          build_record(two_months_ago_day, 10000),  # 2 ヶ月前: 400 kcal
          build_record(last_month_15, 5000),         # 前月:    200 kcal
          build_record(this_month_15, 2500)          # 今月:    100 kcal
        ]
      end

      it "this_month は今月分のみ (100 kcal)" do
        expect(CalorieSavingsService.call(records)[:this_month]).to eq(100)
      end

      it "last_month は前月分のみ (200 kcal)" do
        expect(CalorieSavingsService.call(records)[:last_month]).to eq(200)
      end

      it "total は全期間 (700 kcal)" do
        expect(CalorieSavingsService.call(records)[:total]).to eq(700)
      end
    end

    context "1 歩 = 0.04 kcal の換算式 (整数四捨五入)" do
      it "12 歩 → 0 kcal (12 * 0.04 = 0.48 → 0)" do
        records = [ build_record(this_month_15, 12) ]
        expect(CalorieSavingsService.call(records)[:total]).to eq(0)
      end

      it "13 歩 → 1 kcal (13 * 0.04 = 0.52 → 1)" do
        records = [ build_record(this_month_15, 13) ]
        expect(CalorieSavingsService.call(records)[:total]).to eq(1)
      end

      it "10000 歩 → 400 kcal (10000 * 0.04 = 400.0)" do
        records = [ build_record(this_month_15, 10000) ]
        expect(CalorieSavingsService.call(records)[:total]).to eq(400)
      end
    end

    context "今月の月初 (= today.beginning_of_month) の境界値" do
      it "月初 1 日のレコードも this_month に含む" do
        records = [ build_record(today.beginning_of_month, 1000) ]
        expect(CalorieSavingsService.call(records)[:this_month]).to eq(40)
      end
    end

    context "前月の月末 (= 1 ヶ月前の月末) の境界値" do
      it "前月末日のレコードを last_month に含む" do
        last_month_end = (today - 1.month).end_of_month
        records = [ build_record(last_month_end, 1000) ]
        expect(CalorieSavingsService.call(records)[:last_month]).to eq(40)
      end
    end
  end
end
