# 歩数記録配列から「現在の連続記録日数」を算出する。
#
# 定義:
#   - records は古い順の StepRecord / DemoRecord 配列 (steps フィールドが必須)
#   - 「記録あり」= steps > 0
#   - 今日が記録なし (0 またはレコード未存在) でも昨日まで連続していれば継続扱い
#     (ユーザーに優しい設計 = まだ今日の記録が来ていないだけかもしれない)
#   - 最終的に「直近の連続している日数」を返す
#
# 例: [3000, 0, 4000, 5000, 6000] (古い順) → 戻り値 3 (末尾 3 件が連続)
#     今日が 0 でも昨日以前が連続 → 昨日までのストリーク + 1 でカウントしない (単純に末尾探索)
class StreakCalculatorService
  def self.call(records)
    return 0 if records.empty?

    # 日付昇順で各日の「記録あり/なし」ハッシュを構築
    today     = Date.current
    presence  = records.each_with_object({}) do |r, h|
      h[r.recorded_on] = r.steps > 0
    end

    # 今日から過去に向かって連続日数を数える。
    # 今日のデータがない場合は「未到着」として連続判定に含める (ユーザーに優しい)。
    streak = 0
    date   = today

    loop do
      has_record = presence.key?(date)

      if date == today && !has_record
        # 今日のデータがまだないケース: スキップして昨日から数える
        date -= 1
        next
      end

      break unless has_record && presence[date]

      streak += 1
      date   -= 1
    end

    streak
  end
end
