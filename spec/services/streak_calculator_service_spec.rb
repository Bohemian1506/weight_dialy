require "rails_helper"

RSpec.describe StreakCalculatorService do
  # テスト用に DemoRecord を利用 (DB 不要で軽量)
  DemoRecord = DemoDataService::DemoRecord

  let(:today)     { Date.current }
  let(:yesterday) { today - 1 }

  def build_record(date, steps)
    DemoRecord.new(date, steps, 0, 0)
  end

  describe ".call" do
    context "空配列" do
      it "0 を返す" do
        expect(StreakCalculatorService.call([])).to eq(0)
      end
    end

    context "全レコードが steps = 0" do
      it "0 を返す" do
        records = [
          build_record(today - 2, 0),
          build_record(today - 1, 0),
          build_record(today,     0)
        ]
        expect(StreakCalculatorService.call(records)).to eq(0)
      end
    end

    context "今日だけ 1 件 (steps > 0)" do
      it "1 を返す" do
        records = [ build_record(today, 5000) ]
        expect(StreakCalculatorService.call(records)).to eq(1)
      end
    end

    context "直近 5 日連続 (steps > 0)" do
      it "5 を返す" do
        records = (0..4).map { |i| build_record(today - i, 6000) }
        expect(StreakCalculatorService.call(records)).to eq(5)
      end
    end

    context "直近 5 日連続 + 今日のレコードなし (優しい仕様)" do
      it "5 を返す (今日未到着でも継続とみなす)" do
        # 今日 (today) のレコードを意図的に含めない
        records = (1..5).map { |i| build_record(today - i, 6000) }
        expect(StreakCalculatorService.call(records)).to eq(5)
      end
    end

    context "直近 5 日連続 + 今日 steps = 0 (中断扱い)" do
      it "0 を返す" do
        records  = (1..5).map { |i| build_record(today - i, 6000) }
        records << build_record(today, 0)
        expect(StreakCalculatorService.call(records)).to eq(0)
      end
    end

    context "古い 3 日連続 + 途中 0 + 直近 4 日連続" do
      it "4 を返す (末尾から数える)" do
        old_streak   = (7..9).map  { |i| build_record(today - i, 5000) }
        gap          = [ build_record(today - 6, 0) ]
        recent_streak = (0..3).map { |i| build_record(today - i, 5000) }
        records = old_streak + gap + recent_streak
        expect(StreakCalculatorService.call(records)).to eq(4)
      end
    end

    context "飛び石 (隔日記録)" do
      it "1 を返す (今日のみカウント)" do
        records = [
          build_record(today - 4, 5000),
          build_record(today - 2, 5000),
          build_record(today,     5000)
        ]
        expect(StreakCalculatorService.call(records)).to eq(1)
      end
    end
  end
end
