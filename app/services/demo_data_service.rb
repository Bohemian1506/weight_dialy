# 未ログイン / Android / データ未登録ユーザー向けのデモデータを生成する。
#
# 設計ポイント:
#   - Struct + define_method で StepRecord の duck typing インターフェースを満たす。
#     (StepRecord の estimated_kcal は同一計算式を使用する)
#   - シードを固定 (SEED = 42) し、テストや表示で毎回同じデータになることを保証する。
#   - srand の副作用を避けるため、呼び出し後に元の srand 状態を復元しない
#     (= 通常の Web リクエスト 1 件で完結し、他のランダム処理への影響はない)。
class DemoDataService
  SEED = 42

  # 固定値で生活感のある直近 7 日分パターン。
  # インデックス 0 = 今日, 6 = 7 日前。
  RECENT_7_PATTERN = [
    { steps: 7_200, distance_meters: 5_400, flights_climbed: 12 }, # 今日 (土)
    { steps: 4_800, distance_meters: 3_600, flights_climbed:  8 }, # 昨日 (金) — 週末前
    { steps: 7_800, distance_meters: 5_900, flights_climbed: 14 }, # 2日前 (木)
    { steps: 6_500, distance_meters: 4_900, flights_climbed: 10 }, # 3日前 (水)
    { steps: 7_100, distance_meters: 5_300, flights_climbed: 11 }, # 4日前 (火)
    { steps: 3_200, distance_meters: 2_400, flights_climbed:  5 }, # 5日前 (月) — 少なめ
    { steps: 2_100, distance_meters: 1_600, flights_climbed:  3 } # 6日前 (日) — 週末休息
  ].freeze

  # recorded_on から 23 日前以降は疑似乱数 (固定シード) で生成。休息日はスキップ。
  REST_DAYS = [ 3, 9, 17, 24 ].freeze # 0-base offset (0 = 今日)

  DemoRecord = Struct.new(:recorded_on, :steps, :distance_meters, :flights_climbed) do
    def estimated_kcal
      (steps * 0.04 + flights_climbed * 0.5).round
    end
  end

  # Service 命名規則 (.call) に統一。`sample_records` は内部 alias として残す互換性は不要。
  def self.call
    # ローカル PRNG を使用してグローバル srand 副作用を回避 (Puma マルチスレッド汚染防止)。
    rng     = Random.new(SEED)
    records = []

    30.times do |i|
      date = Date.current - i

      if REST_DAYS.include?(i)
        # 休息日: 0 データとしてスキップ (bar なし扱い)
        next
      elsif i < RECENT_7_PATTERN.size
        pattern = RECENT_7_PATTERN[i]
        records << DemoRecord.new(date, pattern[:steps], pattern[:distance_meters], pattern[:flights_climbed])
      else
        steps    = rng.rand(5_000..9_000)
        distance = rng.rand(3_000..7_000)
        flights  = rng.rand(5..18)
        records << DemoRecord.new(date, steps, distance, flights)
      end
    end

    # 古い順に並べ替えて返す (チャートが左から古い順前提)
    records.sort_by(&:recorded_on)
  end
end
