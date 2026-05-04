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
  Result = Struct.new(:headline, :items, :button_label, keyword_init: true)
  Item   = Struct.new(:name, :kcal, :label, keyword_init: true)

  # ヘッドラインは固定 (= AI 生成にせず一貫したブランドトーンを維持、レイテンシ短縮)。
  # 「今日の消費カロリーならこれ食べられるよ〜」 はユーザー判断 (Issue #42 設計議論) で確定したコピー。
  HEADLINE     = "今日の消費カロリーならこれ食べられるよ〜"
  BUTTON_LABEL = "食べたい物から逆算 →"

  def self.call(estimated_kcal)
    # credentials に api_key が無い環境 (= development デフォルト / test) では AI を呼ばず Static のみ使う。
    # これにより credentials 未設定環境での偶発的な API 呼び出し (= 401 や WebMock 例外) を防止する。
    # production で AI 化したい時は config/credentials/production.yml.enc に anthropic.api_key を入れる。
    if ai_available?
      items = Ai.call(estimated_kcal)
      Rails.logger.info("[CalorieAdviceService] AI suggestion ok (kcal=#{estimated_kcal}, items=#{items.size})")
    else
      items = Static.call(estimated_kcal)
    end
    Result.new(headline: HEADLINE, items: items, button_label: BUTTON_LABEL)
  rescue StandardError => e
    # API failure / timeout / rate limit / JSON parse error すべて広く受けてフォールバック。
    # 細粒度の制御 (= 例外別の retry 等) は polish フェーズで Issue 化して別途。
    Rails.logger.warn("[CalorieAdviceService] AI failed (#{e.class}: #{e.message.truncate(120)}), falling back to static")
    static_items = Static.call(estimated_kcal)
    Result.new(headline: HEADLINE, items: static_items, button_label: BUTTON_LABEL)
  end

  def self.ai_available?
    Rails.application.credentials.dig(:anthropic, :api_key).present?
  end
  private_class_method :ai_available?
end
