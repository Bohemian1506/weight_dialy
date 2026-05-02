# 今日の消費カロリーに基づいて「これ食べてもOK?」提案を生成する。
#
# 設計ポイント:
#   - 外部 API は使わず固定リストから kcal 帯に応じて動的に選ぶ (MVP 範囲)。
#   - 「余裕」「OK」ラベルは kcal の余裕度 (item.kcal / total_kcal) で付与。
#   - 戻り値は Hash: { headline:, items: [{name:, kcal:, label:}, ...], button_label: }
class CalorieAdviceService
  Result = Struct.new(:headline, :items, :button_label, keyword_init: true)
  Item   = Struct.new(:name, :kcal, :label, keyword_init: true)

  BUTTON_LABEL = "食べたい物から逆算 →"

  # kcal 帯別の候補リスト。 :kcal は 1 アイテムあたりの推定カロリー。
  CANDIDATES = {
    tiny: [  # 50 kcal 未満のプラスα向け
      { name: "飴ちゃん 1 個",    kcal: 15 },
      { name: "ガム 1 枚",        kcal: 10 },
      { name: "こんにゃくゼリー", kcal: 25 }
    ],
    small: [ # 100 kcal 未満
      { name: "みたらし 1 本",      kcal:  90 },
      { name: "おにぎり 半分",      kcal:  90 },
      { name: "バナナ 1 本",        kcal:  90 }
    ],
    medium: [ # 200 kcal 未満
      { name: "チョコモナカ 半分",  kcal: 120 },
      { name: "ラテ（無糖）",       kcal:  50 },
      { name: "せんべい 2 枚",      kcal: 100 },
      { name: "コーヒーゼリー",     kcal:  60 }
    ],
    large: [ # 400 kcal 未満
      { name: "みたらし 1 本",      kcal:  90 },
      { name: "チョコモナカ 半分",  kcal: 120 },
      { name: "おにぎり 1 個",      kcal: 180 },
      { name: "プリン",             kcal: 150 }
    ],
    xlarge: [ # 400 kcal 以上
      { name: "ショートケーキ",     kcal: 300 },
      { name: "フラペチーノ",       kcal: 380 },
      { name: "アイスクリーム",     kcal: 200 },
      { name: "おにぎり 2 個",      kcal: 360 },
      { name: "カップラーメン 半分", kcal: 160 }
    ]
  }.freeze

  def self.call(estimated_kcal)
    kcal = estimated_kcal.to_i

    candidates = select_candidates(kcal)
    items      = build_items(candidates.first(3), kcal)

    Result.new(
      headline:     "きょうのプラマイ提案",
      items:        items,
      button_label: BUTTON_LABEL
    )
  end

  def self.select_candidates(kcal)
    pool = case kcal
    when 0...50   then CANDIDATES[:tiny]
    when 50...100 then CANDIDATES[:small]
    when 100...200 then CANDIDATES[:medium]
    when 200...400 then CANDIDATES[:large]
    else            CANDIDATES[:xlarge]
    end
    # kcal が多い場合は複数帯からミックスして多様性を出す
    return pool if kcal < 200

    (CANDIDATES[:small] + pool).uniq { |c| c[:name] }
  end
  private_class_method :select_candidates

  def self.build_items(candidates, total_kcal)
    candidates.map do |c|
      ratio = total_kcal.positive? ? c[:kcal].to_f / total_kcal : 0
      label = if ratio < 0.5
                "余裕"
      elsif ratio < 0.9
                "OK"
      end
      Item.new(name: c[:name], kcal: c[:kcal], label: label)
    end
  end
  private_class_method :build_items
end
