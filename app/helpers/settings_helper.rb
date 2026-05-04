module SettingsHelper
  WEBHOOK_STATUS_LABELS = {
    "success"      => "成功",
    "invalid"      => "エラー",
    "unauthorized" => "認証失敗"
  }.freeze

  # WebhookDelivery#status を Settings 画面表示用の日本語ラベルに変換する。
  # 設計判断: ロジックを view 直書きにしないのは「他画面 (将来の admin/dashboard 等) でも同じラベルが要る」
  # 想定 + view から日本語文字列リテラルを排除したいから (= I18n 化への準備)。
  def webhook_status_label(status)
    WEBHOOK_STATUS_LABELS.fetch(status, status.to_s)
  end

  # CSS クラス名に補間する modifier を許可リスト経由で返す。
  # DB を直接書き換えられた場合などに status カラムに想定外文字列が入っても、CSS クラス補間で
  # 属性破壊や HTML インジェクションが起きないよう許可リスト外は "unknown" にフォールバック。
  def webhook_status_css_modifier(status)
    WEBHOOK_STATUS_LABELS.key?(status) ? status : "unknown"
  end

  # WebhookDelivery から送信件数を抽出 (success 時のみ意味があるため status で分岐)。
  # PR #54 で all-or-nothing rollback 化したため success 時の送信件数 = 保存件数で意味が一致する。
  # invalid 時は「1 件試したが 0 件保存された」となり「1 件」表示が誤読を生むため非表示にする。
  # payload が JSON parse 失敗 (= { raw: "..." }) の場合も nil を返し、view 側で件数表示を省略する。
  def webhook_record_count_for_display(delivery)
    return nil unless delivery.status == "success"
    payload = delivery.payload
    return nil unless payload.is_a?(Hash)
    records = payload["records"]
    return nil unless records.is_a?(Array)
    records.size
  end
end
