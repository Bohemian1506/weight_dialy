# 今日の消費 kcal を身近な食品に換算して表示するためのサービス。
#
# 設計思想:
#   - 「消費 kcal = 抽象的な数字」を「アイス N 個ぶん」に変換して直感的に伝える。
#   - アプリの 3 ステップ思想ステップ ① 「罪悪感を減らす」の補助: 消費を食品で可視化することで
#     「今日は動いた」という小さな達成感を具体的に実感させる。
#
# ランダム性の設計:
#   - 毎日異なる食品が表示される「日替わり」方式。
#   - seed に Date.current.to_s.bytes.sum を使うことで 1 日固定 (= 同日はリロードしても同じ)。
#   - Date.to_s.hash を使わない理由: Ruby 1.9+ でハッシュ値のランダム化が導入されており
#     実行ごとに異なる値になる可能性があるため。bytes.sum は実装依存なく安全。
#   - seed: キーワード引数でテスト時に固定値を注入可能 (= テスト容易性)。
#
# nil 返却の条件:
#   - today_kcal < 90 (= 最小食品 kcal 未満): 意味のある換算にならないため非表示。
#   - フォールバック時に count < 1: 最大 kcal 食品でも today_kcal が 1 個ぶんに満たない場合。
#
# count 上限キャップの設計:
#   - max_count (デフォルト 5) を超える count は UI 上で冗長になる (例: バナナ 11 本ぶん)。
#   - FOODS.shuffle で順序を確定し、count が 1..max_count に収まる最初の食品を採用する。
#   - 全食品で上限を超える場合は最大 kcal 食品で [count, max_count].min にキャップ。
class CalorieEquivalentService
  Item = Struct.new(:emoji, :name, :unit, :kcal, keyword_init: true)
  private_constant :Item

  # 食品定数。外部からの参照を防ぐため private_constant で保護。
  FOODS = [
    Item.new(emoji: "🍦", name: "アイス",            unit: "個", kcal: 200),
    Item.new(emoji: "🍺", name: "缶ビール",          unit: "本", kcal: 140),
    Item.new(emoji: "🍙", name: "おにぎり",          unit: "個", kcal: 180),
    Item.new(emoji: "🍌", name: "バナナ",            unit: "本", kcal:  90),
    Item.new(emoji: "🍫", name: "板チョコ半分",      unit: "枚", kcal: 130),
    Item.new(emoji: "🍡", name: "大福",              unit: "個", kcal: 170),
    Item.new(emoji: "🍗", name: "唐揚げ 3 個",       unit: "皿", kcal: 250),
    Item.new(emoji: "🥮", name: "どら焼き",          unit: "個", kcal: 200),
    Item.new(emoji: "🥛", name: "カップヨーグルト",  unit: "個", kcal:  90),
    Item.new(emoji: "☕", name: "カフェラテ",        unit: "杯", kcal: 150)
  ].freeze
  private_constant :FOODS

  # 最小食品 kcal を定数化。call のたびに FOODS を走査せず一度だけ評価する。
  MIN_KCAL = FOODS.map(&:kcal).min
  private_constant :MIN_KCAL

  # @param today_kcal [Integer] 今日の消費 kcal
  # @param seed [Integer] ランダムシード (テスト時に固定値を注入して確定的な挙動にする)
  # @param max_count [Integer] count の上限 (デフォルト 5)。これを超える count は再抽選 or キャップ
  # @return [Hash{Symbol=>Object}, nil] { emoji:, name:, unit:, count: } or nil (表示しない)
  def self.call(today_kcal, seed: Date.current.to_s.bytes.sum, max_count: 5)
    # MIN_KCAL (最小食品 kcal) 未満は意味のある換算にならないため非表示
    return nil if today_kcal < MIN_KCAL

    rng = Random.new(seed)
    # 同 seed でも候補順をばらけさせ、上限 max_count 超え食品を弾く再抽選を可能にする。
    # (旧実装の FOODS.sample では 1 食品決め打ちで上限超えを skip できなかった)
    shuffled = FOODS.shuffle(random: rng)

    # 1 <= count <= max_count を満たす最初の食品を採用 (再抽選ロジック)
    shuffled.each do |food|
      count = today_kcal / food.kcal  # Integer 除算で切り捨て
      return { emoji: food.emoji, name: food.name, unit: food.unit, count: count } if count >= 1 && count <= max_count
    end

    # フォールバック: 全食品で 1 <= count <= max_count を満たさない場合 (= today_kcal が
    # 非常に高い)、最大 kcal 食品で [count, max_count].min にキャップして返す。
    # count == 0 (today_kcal < food.kcal) の経路も理論上ここに到達するが、現状の FOODS は
    # MIN_KCAL = 90 のため today_kcal >= 90 なら必ず 1 食品以上 count >= 1 になり、count == 0
    # 経路は発生しない。
    largest = FOODS.max_by(&:kcal)
    count = today_kcal / largest.kcal
    return nil if count < 1

    { emoji: largest.emoji, name: largest.name, unit: largest.unit, count: [ count, max_count ].min }
  end
end
