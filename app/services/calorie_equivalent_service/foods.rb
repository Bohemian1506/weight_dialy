# CalorieEquivalentService が表示する食品マスタ (= データテーブル)。
#
# enum でなく別ファイル + Struct 配列にした理由 (= Issue #225):
#   - Rails enum (ActiveRecord) は DB カラム前提のため、Service の静的定数には不適
#   - enumerize / ruby-enum 系 gem は「識別子 1 個の値リスト」用 (= role / status 等)
#   - FOODS は「識別子 + 4 属性 (emoji/name/unit/kcal) のレコード × 10」 = データテーブル構造
#   - データテーブルに enum 系ツールを当てると「属性 1 個は enum、残りは別 Hash」の二重管理になる
#   - 結果: ロジック (= calorie_equivalent_service.rb) と データ (= 本ファイル) を別ファイルに分離するのが最もシンプル
#
# private_constant を付けない理由:
#   - Rails 8 + Zeitwerk では Foods のロードが遅延評価されるため、
#     親ファイル (= calorie_equivalent_service.rb) で `private_constant :Foods` を書くと
#     Foods 定数がまだロードされていない時点で宣言が走り NameError リスクがある。
#     別ファイル化と引き換えに諦めた (= 明示 `require_relative` で回避する手もあるが、
#     Rails の autoload 慣習を尊重する判断)。
#   - 各定数は freeze 済で外部から書き換え不可、実害なし
#   - 元コードでは Item / FOODS / MIN_KCAL すべて private_constant だったが、本リファクタでは
#     「データテーブルとして見えてよい」 と判断 (= 単体テスト等で参照しやすくなる副次効果あり)
class CalorieEquivalentService
  module Foods
    Item = Struct.new(:emoji, :name, :unit, :kcal, keyword_init: true)

    # 食品マスタ。順序に意味はない (= 呼び出し側で shuffle するため)。
    # 中身を増減する時は spec/services/calorie_equivalent_service_spec.rb の seed 別期待値も
    # 追従が必要 (= shuffle 結果が変わるため)。
    ALL = [
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

    # 最小食品 kcal を定数化。call のたびに ALL を走査せず一度だけ評価する。
    MIN_KCAL = ALL.map(&:kcal).min
  end
end
