require "rails_helper"

RSpec.describe BuildHomeDashboardService do
  # UA 定数 (home_spec.rb と同等内容)。
  # トップレベル Object 空間への定数漏れを避けるため `let` に変換 (= 既存 home_spec.rb と整合)。
  let(:iphone_ua) do
    "Mozilla/5.0 (iPhone; CPU iPhone OS 17_2 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.2 Mobile/15E148 Safari/604.1"
  end
  let(:android_ua) do
    "Mozilla/5.0 (Linux; Android 14; Pixel 8) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36"
  end

  # 最小限の ActionDispatch::Request double を生成する。
  # PlatformDetectorService は request.user_agent だけ参照するため、
  # これだけ stub すれば十分 (= 過剰な stub を避ける)。
  def build_request(ua: "")
    instance_double(ActionDispatch::Request, user_agent: ua)
  end

  describe ".call の戻り値型" do
    it "BuildHomeDashboardService::Result を返す" do
      request = build_request
      result  = described_class.call(user: nil, request: request)
      expect(result).to be_a(BuildHomeDashboardService::Result)
    end

    it "Result は immutable (frozen)" do
      request = build_request
      result  = described_class.call(user: nil, request: request)
      expect(result).to be_frozen
    end
  end

  describe ".call" do
    # ─────────────────────────────────────────────────
    # 状態 :guest — user: nil
    # ─────────────────────────────────────────────────
    context "state: :guest (user が nil)" do
      subject(:result) { described_class.call(user: nil, request: build_request) }

      it "state が :guest" do
        expect(result.state).to eq(:guest)
      end

      it "display_name がデフォルト「ユウキ」" do
        expect(result.display_name).to eq("ユウキ")
      end

      it "records が Array" do
        expect(result.records).to be_an(Array)
      end

      it "records が空でない (= デモデータ)" do
        expect(result.records).not_to be_empty
      end

      it "today_record が nil でない (= デモデータから取得)" do
        expect(result.today_record).not_to be_nil
      end

      it "streak が Integer" do
        expect(result.streak).to be_an(Integer)
      end

      it "calorie_savings が Hash で 3 キーを持つ" do
        expect(result.calorie_savings).to be_a(Hash)
          .and include(:this_month, :last_month, :total)
      end

      it "NoMethodError を発生させない (= nil ガード確認)" do
        expect { described_class.call(user: nil, request: build_request) }.not_to raise_error
      end
    end

    # ─────────────────────────────────────────────────
    # 状態 :android — ログイン済み + Android UA + step_records なし (= Capacitor 連携誘導)
    # ─────────────────────────────────────────────────
    context "state: :android (user あり + Android UA + step_records なし)" do
      let(:user) { create(:user) }
      subject(:result) { described_class.call(user: user, request: build_request(ua: android_ua)) }

      it "state が :android" do
        expect(result.state).to eq(:android)
      end

      it "display_name が user.name" do
        expect(result.display_name).to eq(user.name)
      end

      it "records がデモデータ (= step_records なし)" do
        expect(result.records).not_to be_empty
      end

      it "calorie_savings が Hash で 3 キーを持つ" do
        expect(result.calorie_savings).to be_a(Hash)
          .and include(:this_month, :last_month, :total)
      end
    end

    # ─────────────────────────────────────────────────
    # 回帰防止: ログイン済み + Android UA + step_records あり (= Capacitor 同期済 user)
    # 旧版は :android 状態でデモデータを返していた (Issue #158, #159)
    # ─────────────────────────────────────────────────
    context "state: :has_data (user あり + Android UA + step_records あり = Capacitor 同期済)" do
      let(:user) { create(:user) }
      let!(:step_record) { create(:step_record, user: user, recorded_on: Date.current, steps: 9000) }
      subject(:result) { described_class.call(user: user, request: build_request(ua: android_ua)) }

      it "state が :has_data (= Android user でも実データあれば実データ状態を返す)" do
        expect(result.state).to eq(:has_data)
      end

      it "records に DB の StepRecord が含まれる (= デモデータではない)" do
        expect(result.records).to include(step_record)
      end

      it "today_record が今日の StepRecord (= デモではなく自分のデータ)" do
        expect(result.today_record).to eq(step_record)
      end

      it "calorie_savings の this_month が実データ計算 (= 9000 歩 * 0.04 = 360 kcal)" do
        expect(result.calorie_savings[:this_month]).to eq(360)
      end
    end

    # ─────────────────────────────────────────────────
    # 状態 :empty — ログイン済み + iOS + データなし
    # ─────────────────────────────────────────────────
    context "state: :empty (user あり + iOS UA + step_records なし)" do
      let(:user) { create(:user) }
      subject(:result) { described_class.call(user: user, request: build_request(ua: iphone_ua)) }

      it "state が :empty" do
        expect(result.state).to eq(:empty)
      end

      it "display_name が user.name" do
        expect(result.display_name).to eq(user.name)
      end

      it "records がデモデータ (空でない)" do
        expect(result.records).not_to be_empty
      end
    end

    # ─────────────────────────────────────────────────
    # 状態 :has_data — ログイン済み + iOS + データあり
    # ─────────────────────────────────────────────────
    context "state: :has_data (user あり + iOS UA + step_records あり)" do
      let(:user) { create(:user) }
      let!(:step_record) { create(:step_record, user: user, recorded_on: Date.current, steps: 9000) }
      subject(:result) { described_class.call(user: user, request: build_request(ua: iphone_ua)) }

      it "state が :has_data" do
        expect(result.state).to eq(:has_data)
      end

      it "display_name が user.name" do
        expect(result.display_name).to eq(user.name)
      end

      it "records に DB の StepRecord が含まれる" do
        expect(result.records).to include(step_record)
      end

      it "today_record が今日の StepRecord" do
        expect(result.today_record).to eq(step_record)
      end

      it "streak が 1 以上の Integer (= 今日のレコードがある)" do
        expect(result.streak).to be >= 1
      end

      it "calorie_savings の this_month が正しい (= 9000 歩 * 0.04 = 360 kcal)" do
        expect(result.calorie_savings[:this_month]).to eq(360)
      end

      it "calorie_savings の total が正しい (= 全期間で 9000 歩のみ → 360 kcal)" do
        expect(result.calorie_savings[:total]).to eq(360)
      end

      it "advice が CalorieAdviceService::Result (= 9000 歩 → 360 kcal で ZERO_THRESHOLD 超え、通常ステート Result 型)" do
        expect(result.advice).to be_a(CalorieAdviceService::Result)
      end

      it "food_equivalent が Hash または nil" do
        expect(result.food_equivalent).to be_a(Hash).or be_nil
      end
    end

    # ─────────────────────────────────────────────────
    # 状態 :has_data かつ today_kcal < ZERO_THRESHOLD (= 0 歩 / 微歩数、ZeroKcalResult 経路)
    # PR #239 で advice が Result / ZeroKcalResult の 2 種に分離されたため、両経路を spec で検証する。
    # 通常ステート (= 9000 歩) は上の context で Result 型を検証済、本 context は ZeroKcalResult 経路の回帰防止。
    # ─────────────────────────────────────────────────
    context "state: :has_data + today_kcal < ZERO_THRESHOLD (= 0 歩、ZeroKcalResult 経路)" do
      let(:user) { create(:user) }
      let!(:step_record) { create(:step_record, user: user, recorded_on: Date.current, steps: 0) }
      subject(:result) { described_class.call(user: user, request: build_request(ua: iphone_ua)) }

      it "state が :has_data (= step_records.exists? が true なので通常 has_data 状態)" do
        expect(result.state).to eq(:has_data)
      end

      it "advice が CalorieAdviceService::ZeroKcalResult (= 0 歩 → 0 kcal で ZERO_THRESHOLD 未満、空ステート)" do
        expect(result.advice).to be_a(CalorieAdviceService::ZeroKcalResult)
      end

      it "advice.zero_state? が true (= 状態判定 predicate)" do
        expect(result.advice.zero_state?).to be true
      end

      it "advice.items が空配列 (= 食品提案を出さない空ステート)" do
        expect(result.advice.items).to eq([])
      end

      it "advice.body が ZERO_BODY (= view 側 else ブランチで表示する文言)" do
        expect(result.advice.body).to eq("歩数が記録されると、食べていいものを提案するよ。")
      end
    end

    # ─────────────────────────────────────────────────
    # Result field の互換性確認 (= Controller の @xxx 7 本と対応)
    # ─────────────────────────────────────────────────
    describe "Result field の互換性" do
      subject(:result) { described_class.call(user: nil, request: build_request) }

      it "state field が存在する" do
        expect(result).to respond_to(:state)
      end

      it "display_name field が存在する" do
        expect(result).to respond_to(:display_name)
      end

      it "records field が存在する" do
        expect(result).to respond_to(:records)
      end

      it "today_record field が存在する" do
        expect(result).to respond_to(:today_record)
      end

      it "streak field が存在する" do
        expect(result).to respond_to(:streak)
      end

      it "advice field が存在する" do
        expect(result).to respond_to(:advice)
      end

      it "calorie_savings field が存在する" do
        expect(result).to respond_to(:calorie_savings)
      end

      it "food_equivalent field が存在する" do
        expect(result).to respond_to(:food_equivalent)
      end
    end
  end
end
