# 既存の固定リストロジック (= AI service が失敗した時のフォールバック専用)。
# Issue #42 で AI 化する前の CalorieAdviceService 本体ロジックを、構造を変えずに移植している。
# 触る時は CalorieAdviceService::Ai (本命) との 戻り値型 (Item 配列) 互換を必ず維持すること。
class CalorieAdviceService
  class Static
    CANDIDATES = {
      tiny: [  # 50 kcal 未満
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
        { name: "ラテ(無糖)",         kcal:  50 },
        { name: "せんべい 2 枚",      kcal: 100 },
        { name: "コーヒーゼリー",     kcal:  60 }
      ],
      large: [ # 400 kcal 未満
        { name: "おにぎり 1 個",      kcal: 180 },
        { name: "プリン",             kcal: 150 },
        { name: "チョコモナカ 半分",  kcal: 120 },
        { name: "みたらし 1 本",      kcal:  90 }
      ],
      xlarge: [ # 400 kcal 以上
        { name: "ショートケーキ",     kcal: 300 },
        { name: "フラペチーノ",       kcal: 380 },
        { name: "アイスクリーム",     kcal: 200 },
        { name: "おにぎり 2 個",      kcal: 360 },
        { name: "カップラーメン 半分", kcal: 160 }
      ]
    }.freeze

    # @param estimated_kcal [Integer]
    # @return [Array<CalorieAdviceService::Item>] 3 件
    def self.call(estimated_kcal)
      kcal = estimated_kcal.to_i
      candidates = select_pool(kcal)
      build_items(candidates.first(3), kcal)
    end

    def self.select_pool(kcal)
      pool = case kcal
      when 0...50    then CANDIDATES[:tiny]
      when 50...100  then CANDIDATES[:small]
      when 100...200 then CANDIDATES[:medium]
      when 200...400 then CANDIDATES[:large]
      else                CANDIDATES[:xlarge]
      end
      # 200 kcal 以上は small 帯と混ぜて多様性を出す (= 旧 CalorieAdviceService の挙動を継承)
      return pool if kcal < 200
      (CANDIDATES[:small] + pool).uniq { |c| c[:name] }
    end

    def self.build_items(candidates, total_kcal)
      candidates.map do |c|
        ratio = total_kcal.positive? ? c[:kcal].to_f / total_kcal : 0
        label = if ratio < 0.5      then "余裕"
        elsif    ratio < 0.9        then "OK"
        end
        CalorieAdviceService::Item.new(name: c[:name], kcal: c[:kcal], label: label)
      end
    end

    private_class_method :select_pool, :build_items
  end
end
