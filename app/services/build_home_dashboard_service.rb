# ホームダッシュボード表示に必要な全データを一括で組み立てる。
#
# 設計思想:
#   - HomeController#index の private メソッド群をここに集約し、Controller を薄くする。
#   - 各サービスへの依存は明示的な呼び出しで表現し、暗黙の順序依存を排除する。
#   - Data.define (Ruby 3.2+) で immutable な Result 型を定義。
#     Struct の上位互換で等値性・パターンマッチングに対応し、テスト検証が容易。
#
# nil ガード設計:
#   - user が nil (= 未ログイン) の場合、state: :guest を先に確定する。
#   - fetch_records / calorie_savings 分岐は state で決定するため、
#     user が nil のまま step_records を呼び出す経路は存在しない。
class BuildHomeDashboardService
  Result = Data.define(
    :state, :display_name, :records, :today_record,
    :streak, :advice, :calorie_savings, :food_equivalent
  )

  class << self
    # @param user  [User, nil]    current_user (未ログイン時は nil)
    # @param request [ActionDispatch::Request] UA 判定のためのリクエストオブジェクト
    # @return [Result]
    def call(user:, request:)
      state        = determine_state(user, request)
      records      = fetch_records(user, state)
      today_record = records.find { |r| r.recorded_on == Date.current } || records.last

      calorie_savings =
        if state == :iphone_with_data
          CalorieSavingsService.call_for_user(user)
        else
          CalorieSavingsService.call(records)
        end

      Result.new(
        state:           state,
        display_name:    user&.name || "ユウキ",
        records:         records,
        today_record:    today_record,
        streak:          StreakCalculatorService.call(records),
        advice:          CalorieAdviceService.call(today_record&.estimated_kcal.to_i),
        calorie_savings: calorie_savings,
        food_equivalent: CalorieEquivalentService.call(today_record&.estimated_kcal.to_i)
      )
    end

    private

    # state 判定の優先順位 (= 2026-05-06 Day 8 で見直し):
    # 1. 未ログイン → :guest
    # 2. 実データあり → :iphone_with_data (= platform に関わらず実データ表示、誤称だが互換性のため名前は据え置き)
    # 3. Android UA + データなし → :android (= Capacitor 連携誘導バナー)
    # 4. それ以外 + データなし → :empty (= iOS Shortcut 誘導バナー)
    #
    # 旧版は 2 と 3 が逆順で「Android Capacitor user は同期成功してもデモデータが永久表示」される設計バグだった
    # (= Issue #158, #159 で発覚)。Capacitor アプリの overrideUserAgent に "Android" が含まれるため、
    # データの有無を見ずに :android 状態を強制するとデモデータが返る。
    def determine_state(user, request)
      return :guest unless user
      return :iphone_with_data if user.step_records.exists?

      platform = PlatformDetectorService.from_request(request)
      return :android if platform == :android

      :empty
    end

    # 直近 30 日のレコードを返す (チャート描画用)。
    # guest / android / empty は DemoDataService のデモデータで代替。
    def fetch_records(user, state)
      if state == :iphone_with_data
        user.step_records
            .where(recorded_on: 30.days.ago.to_date..Date.current)
            .order(:recorded_on)
            .to_a
      else
        DemoDataService.call
      end
    end
  end
end
