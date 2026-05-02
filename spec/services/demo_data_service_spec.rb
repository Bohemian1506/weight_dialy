require "rails_helper"

RSpec.describe DemoDataService do
  # srand のグローバル副作用をリセットしてテスト間の干渉を防ぐ
  after { srand }

  describe ".call" do
    subject(:records) { DemoDataService.call }

    it "26 件のレコードを返す (30 日 - 休息日 4 件)" do
      expect(records.size).to eq(26)
    end

    it "全要素が DemoRecord インスタンスである" do
      expect(records).to all(be_a(DemoDataService::DemoRecord))
    end

    it "estimated_kcal メソッドが定義されていて整数を返す" do
      record = records.first
      expect(record).to respond_to(:estimated_kcal)
      expect(record.estimated_kcal).to be_a(Integer)
    end

    it "recorded_on が Date.current を含む直近 30 日の範囲内である" do
      today     = Date.current
      range_min = today - 29
      records.each do |r|
        expect(r.recorded_on).to be_between(range_min, today)
      end
    end

    it "古い順 (recorded_on 昇順) に並んでいる" do
      dates = records.map(&:recorded_on)
      expect(dates).to eq(dates.sort)
    end

    describe "直近 7 日分の固定値 (RECENT_7_PATTERN)" do
      # RECENT_7_PATTERN のインデックス 0 = 今日, 6 = 6 日前。
      # REST_DAYS = [3, 9, 17, 24] のうちインデックス 3 は直近 7 日に含まれる。
      # 休息日のインデックスはレコードが存在しないため検証をスキップする。
      today = Date.current

      DemoDataService::RECENT_7_PATTERN.each_with_index do |expected, i|
        if DemoDataService::REST_DAYS.include?(i)
          it "#{i} 日前は休息日のためレコードが存在しない" do
            date = today - i
            record = DemoDataService.call.find { |r| r.recorded_on == date }
            expect(record).to be_nil
          end
        else
          it "#{i} 日前の steps が #{expected[:steps]} である" do
            date   = today - i
            record = DemoDataService.call.find { |r| r.recorded_on == date }
            expect(record).not_to be_nil, "#{date} のレコードが見つかりません"
            expect(record.steps).to eq(expected[:steps])
          end
        end
      end
    end

    describe "再現性 (固定シード)" do
      it "同じ srand(SEED) で複数回呼んでも同じ steps 列を返す" do
        first_run  = DemoDataService.call.map(&:steps)
        second_run = DemoDataService.call.map(&:steps)
        expect(first_run).to eq(second_run)
      end
    end

    describe "グローバル乱数状態への副作用なし (Random.new(SEED) ローカル PRNG 使用)" do
      it "呼び出し後の Kernel#rand 状態が破壊されない" do
        srand(12_345)
        expected_next = rand
        srand(12_345)
        DemoDataService.call
        # ローカル PRNG (Random.new) を使うので、グローバル srand 状態は変化しない
        expect(rand).to eq(expected_next)
      end
    end
  end
end
