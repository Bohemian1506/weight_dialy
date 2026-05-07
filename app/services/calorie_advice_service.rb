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
  # 通常時 (= 食品提案あり、items 3 件) の Result。
  # ai_used: AI 経路で生成されたかのフラグ。dashboard で「Powered by Claude」 バッジ表示の出し分けに使う (Issue #75)。
  # AI 成功時 true / Static フォールバック時 false。ユーザーには UI 出力にしか影響せず PII は含めない。
  #
  # body / zero_state? は ZeroKcalResult との view 側 duck type 統一のため定義 (= 通常時は nil / false)。
  Result = Struct.new(:headline, :items, :button_label, :ai_used, keyword_init: true) do
    def body = nil
    def zero_state? = false
  end

  Item = Struct.new(:name, :kcal, :label, keyword_init: true)

  # 0 kcal 時 (= ZERO_THRESHOLD 未満、食品提案を出さない空ステート) の Result。
  #
  # 専用クラスに分離した理由 (= Issue Tier 2 #5、refactor-candidates.md 由来):
  #   - 旧設計は単一 Result Struct に body フィールドを持ち、3/4 ケースで常に nil = デッドフィールド問題があった
  #   - 「特殊ステート (= 0 kcal、食品提案なし)」 と「通常ステート (= 食品提案あり)」 はデータ shape が異なる
  #     → 1 つの Struct で表現するより 2 つに分ける方が「body が nil なのは異常?正常?」 と
  #       読者が迷わない (= 単一責任、構造から意図が読める)
  #   - view 側互換性のため items / button_label / ai_used / body のデリゲートメソッドを生やす
  #     (= view は items.any? で分岐 + advice.body 表示で動作中、書き換えなし)
  #
  # 「専用 Result クラス分割」 vs 「Null Object パターン」 vs 「現状維持」 の 3 案検討結果:
  #   1. 専用 Result クラス分割 (= 採用) — 2 Struct で意図明確、view 側 duck type 互換
  #   2. Null Object パターン — OOP 教科書的だが、Rails では Struct ベースの方が読みやすい
  #   3. 現状維持 — body デッドフィールド問題が残る、新規読者の混乱源
  ZeroKcalResult = Struct.new(:headline, :body, keyword_init: true) do
    def items = []
    def button_label = nil
    def ai_used = false
    def zero_state? = true
  end

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
      Result.new(headline: HEADLINE, items: items, button_label: BUTTON_LABEL, ai_used: true)
    else
      items = Static.call(estimated_kcal)
      Result.new(headline: HEADLINE, items: items, button_label: BUTTON_LABEL, ai_used: false)
    end
  rescue StandardError => e
    # API failure / timeout / rate limit / JSON parse error すべて広く受けてフォールバック。
    # 細粒度の制御 (= 例外別の retry 等) は polish フェーズで Issue 化して別途。
    Rails.logger.warn("[CalorieAdviceService] AI failed (#{e.class}: #{e.message.truncate(120)}), falling back to static")
    static_items = Static.call(estimated_kcal)
    Result.new(headline: HEADLINE, items: static_items, button_label: BUTTON_LABEL, ai_used: false)
  end

  def self.zero_kcal_result
    ZeroKcalResult.new(headline: ZERO_HEADLINE, body: ZERO_BODY)
  end
  private_class_method :zero_kcal_result

  def self.ai_available?
    Rails.application.credentials.dig(:anthropic, :api_key).present?
  end
  private_class_method :ai_available?
end
