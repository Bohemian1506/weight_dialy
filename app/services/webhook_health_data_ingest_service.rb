# Webhook 受信エンドポイント (= WebhooksController#health_data) から切り出された
# ヘルスデータ ingest ロジック (= ダッシュボード Tier 2 #4 由来、refactor-candidates.md)。
#
# 設計思想 (= fat controller 解消の教材):
#   - controller は HTTP の入出力 (params / response / 監査ログ / 認証) に専念
#   - service はドメインロジック (ペイロード検証 + パース + 永続化) に専念
#   - 失敗は **例外ベース** で controller の rescue ladder に委譲 (= 早期 return パターンを統一化)
#
# Service が raise する例外:
#   - InvalidPayload: ペイロード形式違反 (= records が Array でない / recorded_on 形式不正 / 数値型不正)
#                     → controller で 422 + 監査ログ "invalid" 経路へ
#   - ActiveRecord::RecordInvalid: AR バリデーション違反 (= 負数 / 不正な日付値域)
#                                  → controller で同じく 422 + 監査ログ "invalid" 経路へ (service では rescue しない)
#
# 旧 controller の `WebhooksController::InvalidPayload` は本 service に昇格 (= 例外の発生源と service が同じ場所にある方が読みやすい)。
#
# unit spec の判断履歴 (= Tier 2 #4 教材ポイント、学び 33 テスタビリティ軸):
#   - PR #241 (切り出し時): 既存 `spec/requests/webhooks_spec.rb` (= 110 examples) が controller + service 統合テストとして
#     異常系含め網羅 / 切り出し前後で挙動完全保持のため、unit spec は **将来別経路 (= Strava ingest 等) 追加時に検討** と判断
#   - PR #244 (= Issue #242 で起票、本日 follow-up 着地): **「契約のドキュメント化」 教材性向上 + 他 service との一貫性**
#     を主動機に、別経路追加待たず unit spec 前倒し追加 (= `spec/services/webhook_health_data_ingest_service_spec.rb`、22 examples)
#   - 教材ポイント: 「Service 切り出し = 即 unit spec 追加」 を機械的に適用せず、判定軸 4 つ (= 学び 33) で都度判断する。
#     **判断の前提が変わったら判断を更新する** (= PR #241 → #244 で teaching moment、weight_dialy の判断ログ運用と一致)。
class WebhookHealthDataIngestService
  # ペイロード形式違反を表す内部例外。controller の rescue ladder で捕まえて 422 + 監査ログ経路へ。
  # JSON::ParserError や RecordInvalid と並列で 422 経路に流すために導入 (= webhook 受信エンドポイントは
  # 「機械同士の契約」 なので fail-fast、silent 正規化しない方針)。
  InvalidPayload = Class.new(StandardError)

  # Strict ISO 8601 (yyyy-MM-dd) parser. 配布版 Apple Shortcut は yyyy-MM-dd zero-padded で送る契約のため、
  # それ以外のフォーマット (yyyy/MM/dd, M/d/yyyy 米国式 vs 欧州式) を Date.parse で寛容に解釈すると
  # 「同じ日のつもりが別日として保存」「2 月のデータが 5 月になる」事故を生むため reject する。
  #
  # NOTE: Date.strptime("%Y-%m-%d") は仕様上 zero padding 不足 ("2026-5-3") を許容してしまうため、
  # 正規表現で「正確に 4-2-2 桁」を先に検査してから Date.strptime に渡す二段構え。
  ISO_DATE_FORMAT = /\A\d{4}-\d{2}-\d{2}\z/

  # @param records_data [Array<Hash>, Object] ペイロードの records 配列 (Array 以外は raise)
  # @param user [User] 認証済 webhook user (= controller の @webhook_user を渡す)
  # @return [Integer] accepted_count (= 保存できたレコード件数)
  # @raise [InvalidPayload] records が Array でない / recorded_on の形式不正 / 数値フィールド型不正
  # @raise [ActiveRecord::RecordInvalid] AR バリデーション違反 (= controller 側で rescue する想定)
  def self.call(records_data:, user:)
    raise InvalidPayload, I18n.t("webhook.errors.missing_records_array") unless records_data.is_a?(Array)

    accepted = 0

    # All-or-nothing: wrap in a transaction so that if any record fails validation
    # the entire batch rolls back and the caller can safely retry the whole payload.
    StepRecord.transaction do
      records_data.each do |entry|
        recorded_on = parse_recorded_on(entry["recorded_on"])
        record = StepRecord.find_or_initialize_by(user: user, recorded_on: recorded_on)

        # Slice only the keys the caller sent; compact removes nils so that
        # missing keys do not overwrite existing values with nil/0.
        # NOTE: we cannot distinguish "key absent" from "explicit 0" because both
        # arrive as falsy in JSON; partial-update semantics treat absent ≠ 0.
        updates = {
          steps:           parse_numeric(entry["steps"], "steps"),
          distance_meters: parse_numeric(entry["distance_meters"], "distance_meters"),
          flights_climbed: parse_numeric(entry["flights_climbed"], "flights_climbed")
        }.compact

        record.assign_attributes(updates)
        record.save!
        accepted += 1
      end
    end

    accepted
  end

  def self.parse_recorded_on(raw)
    raise InvalidPayload, I18n.t("webhook.errors.recorded_on_required") if raw.blank?

    raw_str = raw.to_s
    unless raw_str.match?(ISO_DATE_FORMAT)
      raise InvalidPayload, I18n.t("webhook.errors.recorded_on_invalid_format")
    end

    Date.strptime(raw_str, "%Y-%m-%d")
  rescue Date::Error
    # 月日の値域違反 (例: "2026-13-99")
    raise InvalidPayload, I18n.t("webhook.errors.recorded_on_invalid_format")
  end
  private_class_method :parse_recorded_on

  # 数値フィールド (steps / distance_meters / flights_climbed) を厳格パースする (Issue #52)。
  # nil は許容 (= partial-update セマンティクス維持) するが、Hash や String など Integer/Float でない型は reject。
  # 防ぎたい事故: Apple HealthKit Sample object `{ value: 12345, unit: "count" }` が来た時に、
  # AR の type cast で silent に 0 として保存される (= 「動いてるけど中身がゼロ」 の見えないバグ温床)。
  #
  # Float は「整数値の Float」 (例: 8000.0) のみ許容する。9999.9 のような小数は silent に切り捨てられて
  # 1 歩ぶん失われる事故を防ぐため reject する (= Apple Shortcuts が JSON 数値を 8000.0 で送る可能性を残しつつ、
  # 真の小数値は reject、code-reviewer 指摘由来)。
  def self.parse_numeric(raw, field_name)
    return nil if raw.nil?

    case raw
    when Integer
      raw
    when Float
      unless raw == raw.to_i
        raise InvalidPayload, I18n.t("webhook.errors.must_be_whole_number",
                                     field: I18n.t("webhook.fields.#{field_name}"),
                                     value: raw)
      end
      raw.to_i
    else
      raise InvalidPayload, I18n.t("webhook.errors.must_be_number",
                                   field: I18n.t("webhook.fields.#{field_name}"),
                                   value: raw.to_s.truncate(40).gsub(/[[:cntrl:]]/, "?"),
                                   type: raw.class)
    end
  end
  private_class_method :parse_numeric
end
