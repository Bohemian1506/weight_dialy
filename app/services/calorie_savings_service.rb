# 歩数記録配列から「貯カロリー」(= 歩数を kcal 換算した累積) を算出する。
#
# 設計思想:
#   - アプリの 3 ステップ思想 (① 罪悪感を減らす → ② 習慣化 → ③ ガチ運動) のステップ ① の核機能。
#   - 「貯カロリー」直球造語で「kcal = 罪」を「kcal = 貯めるもの」に能動的反転。
#   - 月リセット + 累計の二段構造で、ステップ ① (累計達成感) と ステップ ② (月単位習慣化) 両対応。
#
# 数値プレッシャー回避:
#   - 戻り値は this_month / last_month / total の 3 値だけ (= 並列表示用)。
#   - 前月比 / 矢印 / 色分けはこの service では計算しない (= UI 側でも提示しない方針)。
#   - 詳細根拠: memory project_weight_dialy_three_step_philosophy.md
#
# 換算式:
#   - 1 歩 = 0.04 kcal (= 体重 70kg 前提のおおよその平均値)
#   - 体重設定を要求しないことで、ステップ ① の人を「面倒くさい → 離脱」から守る。
#   - 精密化は v1.3+ (Issue #43 ガチ運動モード) で別 service として分岐予定。
class CalorieSavingsService
  CALORIES_PER_STEP = 0.04

  class << self
    # @param records [Array<#recorded_on, #steps>] StepRecord または DemoRecord の配列 (全期間想定)
    # @return [Hash{Symbol=>Integer}] { this_month:, last_month:, total: } 各 kcal を整数で返す
    def call(records)
      return zero_result if records.blank?

      today = Date.current
      this_month_range = today.beginning_of_month..today.end_of_month
      last_month_date  = today - 1.month
      last_month_range = last_month_date.beginning_of_month..last_month_date.end_of_month

      {
        this_month: kcal_in_range(records, this_month_range),
        last_month: kcal_in_range(records, last_month_range),
        total:      kcal_total(records)
      }
    end

    # @param user [User, nil] ログイン済みユーザー (AR ベースの SQL 集計、本番ユーザー用)
    # @return [Hash{Symbol=>Integer}] { this_month:, last_month:, total: } 各 kcal を整数で返す
    #
    # call(records) との違い:
    #   - 配列を全件メモリに載せず、DB 側で SUM 集計する (= N+1 / メモリ効率)。
    #   - scope が user.step_records に限定されるため、他ユーザーのレコードが混入しない。
    #   - recorded_on は date 型のため time zone の影響を受けない。
    #
    # 構造上 nil 来ない (= 呼び出し側 BuildHomeDashboardService で state ガード済み) が、
    # メソッド単体での安全性のため call(records) の records.blank? ガードと対称に nil ガード。
    def call_for_user(user)
      return zero_result if user.nil?

      today = Date.current
      this_month_range = today.beginning_of_month..today.end_of_month
      last_month_date  = today - 1.month
      last_month_range = last_month_date.beginning_of_month..last_month_date.end_of_month

      {
        this_month: kcal_in_range_sql(user, this_month_range),
        last_month: kcal_in_range_sql(user, last_month_range),
        total:      kcal_total_sql(user)
      }
    end

    private

    def zero_result
      { this_month: 0, last_month: 0, total: 0 }
    end

    def kcal_in_range(records, range)
      steps_sum = records.select { |r| range.cover?(r.recorded_on) }.sum(&:steps)
      (steps_sum * CALORIES_PER_STEP).round
    end

    def kcal_total(records)
      (records.sum(&:steps) * CALORIES_PER_STEP).round
    end

    def kcal_in_range_sql(user, range)
      (user.step_records.where(recorded_on: range).sum(:steps) * CALORIES_PER_STEP).round
    end

    def kcal_total_sql(user)
      (user.step_records.sum(:steps) * CALORIES_PER_STEP).round
    end
  end
end
