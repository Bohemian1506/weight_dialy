# 今日の消費カロリーから「これ食べてもOK?」提案を生成する。
#
# Issue #42 で AI 化: Anthropic Claude Haiku 4.5 を一次情報源とし、
# API 失敗時は固定リスト (CalorieAdviceService::Static) にフォールバック。
#
# 設計ポリシー:
# - アプリの 3 ステップ思想 (① 罪悪感を減らす → ② 習慣化 → ③ ガチ運動) のステップ ① 強化
# - 数値プレッシャー回避: AI 出力にも「強要表現禁止」をプロンプトで指示
# - 詳細根拠: memory project_weight_dialy_three_step_philosophy.md
class CalorieAdviceService
  # ai_used: AI 経路で生成されたかのフラグ。dashboard で「Powered by Claude」バッジ表示の出し分けに使う (Issue #75)。
  # body: 食品提案カード本文 (= 0 kcal 時専用、items が空の時に view が headline と一緒に表示する空ステート用テキスト)。
  # AI 成功時 true / Static フォールバック時 false。ユーザーには UI 出力にしか影響せず PII は含めない。
  Result = Struct.new(:headline, :items, :button_label, :ai_used, :body, keyword_init: true)
  Item   = Struct.new(:name, :kcal, :label, keyword_init: true)

  # ヘッドラインは固定 (= AI 生成にせず一貫したブランドトーンを維持、レイテンシ短縮)。
  # 「今日の消費カロリーならこれ食べられるよ〜」 はユーザー判断 (Issue #42 設計議論) で確定したコピー。
  HEADLINE     = "今日の消費カロリーならこれ食べられるよ〜"
  BUTTON_LABEL = "食べたい物から逆算 →"

  # 消費 0 (= しきい値未満) 時の専用ステート (= Issue #163、3 ステップ思想 ① 罪悪感を減らす を遵守)。
  # 食品提案を出さず、「今日まだスタート前」の優しいメッセージに切り替える。
  #
  # しきい値 30 の根拠 (= 二重根拠):
  #   1. ゼロ除算防御: 純粋にバグ防止だけなら `< 1` で済む (= ratio = food_kcal / total_kcal が 0/0 で全件「余裕」になる元凶を断つ)
  #   2. UX 文脈: 「ほぼ動いてない人 (= 数 kcal 消費)」にバナナ 90 kcal 提案するのも違和感 (= 罪悪感を増やしうる)。
  #      CANDIDATES[:tiny] 最小値 10 kcal の 3 倍 (= 飴ちゃん 3 個分は消費している) を「最低限スタート切った」基準として採用。
  # → ゼロ除算技術ガード + UX しきい値の 2 軸を 1 つの定数で表現。両方の観点が変わる時はそれぞれ別の場所に育てる可能性あり (v1.1 で管理画面化検討)。
  ZERO_THRESHOLD = 30
  ZERO_HEADLINE  = "今日のスタートはここから"
  ZERO_BODY      = "歩数が記録されると、食べていいものを提案するよ。"

  def self.call(estimated_kcal)
    # 消費 0 kcal (= しきい値未満) の時は AI / Static を呼ばず即座に空ステートを返す。
    # 理由: ratio = 0 で全食品が「余裕」判定になる誤誘導 (= Issue #163) を排除、AI コストも節約、再発防止のためビジネスロジックを AI に委ねない。
    return zero_kcal_result if estimated_kcal.to_i < ZERO_THRESHOLD

    # credentials に api_key が無い環境 (= development デフォルト / test) では AI を呼ばず Static のみ使う。
    # これにより credentials 未設定環境での偶発的な API 呼び出し (= 401 や WebMock 例外) を防止する。
    # production で AI 化したい時は config/credentials/production.yml.enc に anthropic.api_key を入れる。
    if ai_available?
      items = Ai.call(estimated_kcal)
      Rails.logger.info("[CalorieAdviceService] AI suggestion ok (kcal=#{estimated_kcal}, items=#{items.size})")
      Result.new(headline: HEADLINE, items: items, button_label: BUTTON_LABEL, ai_used: true, body: nil)
    else
      items = Static.call(estimated_kcal)
      Result.new(headline: HEADLINE, items: items, button_label: BUTTON_LABEL, ai_used: false, body: nil)
    end
  rescue StandardError => e
    # API failure / timeout / rate limit / JSON parse error すべて広く受けてフォールバック。
    # 細粒度の制御 (= 例外別の retry 等) は polish フェーズで Issue 化して別途。
    Rails.logger.warn("[CalorieAdviceService] AI failed (#{e.class}: #{e.message.truncate(120)}), falling back to static")
    static_items = Static.call(estimated_kcal)
    Result.new(headline: HEADLINE, items: static_items, button_label: BUTTON_LABEL, ai_used: false, body: nil)
  end

  def self.zero_kcal_result
    Result.new(headline: ZERO_HEADLINE, items: [], button_label: nil, ai_used: false, body: ZERO_BODY)
  end
  private_class_method :zero_kcal_result

  def self.ai_available?
    Rails.application.credentials.dig(:anthropic, :api_key).present?
  end
  private_class_method :ai_available?
end
