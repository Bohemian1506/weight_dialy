class WebhooksController < ActionController::API
  # API クライアント (Apple Shortcuts / curl) からの呼び出し専用エンドポイント。
  # ActionController::API 継承は Rails 標準の API-only パターンで、CSRF 保護 / browser check / cookie /
  # session を含まない (skip_forgery_protection 等の禁止 workaround とは別物 — そもそも入っていない)。
  # 認証は Bearer token (authenticate_webhook!) で行う。

  # ペイロード形式違反 (recorded_on の形式不正など) を表す内部例外。
  # JSON::ParserError や RecordInvalid と並列で 422 + 監査ログ経路に流すために導入。
  # webhook 受信エンドポイントは「機械同士の契約」なので fail-fast (silent 正規化しない) 方針。
  InvalidPayload = Class.new(StandardError)

  before_action :read_raw_body
  before_action :authenticate_webhook!

  def health_data
    parsed = JSON.parse(@raw_body)
    records_data = parsed["records"]

    unless records_data.is_a?(Array)
      record_delivery!(status: "invalid", accepted_count: 0, error_message: "missing 'records' array")
      render json: { error: "Invalid payload" }, status: :unprocessable_content
      return
    end

    accepted = upsert_records(records_data)
    record_delivery!(status: "success", accepted_count: accepted)
    render json: { accepted: accepted }, status: :ok
  rescue JSON::ParserError => e
    record_delivery!(status: "invalid", accepted_count: 0, error_message: "JSON parse error: #{e.message.truncate(120)}")
    render json: { error: "Invalid payload" }, status: :unprocessable_content
  rescue InvalidPayload => e
    record_delivery!(status: "invalid", accepted_count: 0, error_message: e.message.truncate(120))
    render json: { error: "Invalid payload" }, status: :unprocessable_content
  rescue ActiveRecord::RecordInvalid => e
    # 個々のレコードのバリデーション違反 (負数 / 不正な日付等) を 500 ではなく 422 + 監査ログで返す。
    # rails-implementer の意図 (全体失敗方式) を実装まで貫徹するため。
    record_delivery!(status: "invalid", accepted_count: 0, error_message: "RecordInvalid: #{e.message.truncate(120)}")
    render json: { error: "Invalid payload" }, status: :unprocessable_content
  end

  private

  # Read the raw body once and store it for both authentication and parsing.
  # JSON middleware can consume the IO stream, so reading here ensures we always
  # have the original bytes regardless of middleware ordering.
  # Size cap (1MB) is a DoS guard — a single day's HealthKit aggregate is well under 1KB,
  # so 1MB is generous; payloads above this are rejected with 413 before any parsing.
  MAX_BODY_BYTES = 1.megabyte

  def read_raw_body
    @raw_body = request.body.read(MAX_BODY_BYTES + 1)
    if @raw_body && @raw_body.bytesize > MAX_BODY_BYTES
      render json: { error: "Payload too large" }, status: :content_too_large and return
    end
    @raw_body ||= ""
    request.body.rewind
  end

  def authenticate_webhook!
    token = extract_bearer_token
    @webhook_user = token.present? ? User.find_by(webhook_token: token) : nil

    # Use secure_compare to prevent timing attacks.
    # Both sides are converted to String so the comparison is always same-length safe.
    token_valid = @webhook_user &&
                  ActiveSupport::SecurityUtils.secure_compare(
                    @webhook_user.webhook_token.to_s,
                    token.to_s
                  )

    return if token_valid

    # Intentionally vague: do not reveal whether the token or the user was the problem.
    record_delivery!(status: "unauthorized", error_message: "bearer token mismatch or missing", user: nil)
    render json: { error: "Unauthorized" }, status: :unauthorized and return
  end

  def extract_bearer_token
    request.headers["Authorization"]&.delete_prefix("Bearer ")&.strip
  end

  # Strict ISO 8601 (yyyy-MM-dd) parser. 配布版 Apple Shortcut は yyyy-MM-dd zero-padded で送る契約のため、
  # それ以外のフォーマット (yyyy/MM/dd, M/d/yyyy 米国式 vs 欧州式) を Date.parse で寛容に解釈すると
  # 「同じ日のつもりが別日として保存」「2 月のデータが 5 月になる」事故を生むため reject する。
  #
  # NOTE: Date.strptime("%Y-%m-%d") は仕様上 zero padding 不足 ("2026-5-3") を許容してしまうため、
  # 正規表現で「正確に 4-2-2 桁」を先に検査してから Date.strptime に渡す二段構え。
  ISO_DATE_FORMAT = /\A\d{4}-\d{2}-\d{2}\z/

  # truncate を inspect の前にかけることで、攻撃者が巨大な recorded_on 値 (1MB body キャップ内で
  # 数百 KB を詰める) を送った時に、エラーメッセージ生成段階で巨大文字列が一時的にヒープに乗るのを防ぐ。
  def parse_recorded_on(raw)
    raise InvalidPayload, "recorded_on is required" if raw.blank?
    raw_str = raw.to_s
    truncated = raw_str.truncate(40).inspect
    unless raw_str.match?(ISO_DATE_FORMAT)
      raise InvalidPayload, "recorded_on must be yyyy-MM-dd format: got #{truncated}"
    end
    Date.strptime(raw_str, "%Y-%m-%d")
  rescue Date::Error
    # 月日の値域違反 (例: "2026-13-99")
    raise InvalidPayload, "recorded_on must be yyyy-MM-dd format: got #{truncated}"
  end

  # 数値フィールド (steps / distance_meters / flights_climbed) を厳格パースする (Issue #52)。
  # nil は許容 (= partial-update セマンティクス維持) するが、Hash や String など Integer/Float でない型は reject。
  # 防ぎたい事故: Apple HealthKit Sample object `{ value: 12345, unit: "count" }` が来た時に、
  # AR の type cast で silent に 0 として保存される (= 「動いてるけど中身がゼロ」の見えないバグ温床)。
  #
  # Float は「整数値の Float」(例: 8000.0) のみ許容する。9999.9 のような小数は silent に切り捨てられて
  # 1 歩ぶん失われる事故を防ぐため reject する (= Apple Shortcuts が JSON 数値を 8000.0 で送る可能性を残しつつ、
  # 真の小数値は reject、code-reviewer 指摘 ⚠️)。
  def parse_numeric(raw, field_name)
    return nil if raw.nil?
    case raw
    when Integer
      raw
    when Float
      raise InvalidPayload, "#{field_name} must be a whole number, got Float #{raw}" unless raw == raw.to_i
      raw.to_i
    else
      raise InvalidPayload, "#{field_name} must be a number, got #{raw.class}: #{raw.to_s.truncate(40).inspect}"
    end
  end

  # Upsert each day's record, updating only the keys present in the payload.
  # Keys absent from the payload are left unchanged (partial-update semantics).
  # All-or-nothing: wrap in a transaction so that if any record fails validation
  # the entire batch rolls back and the caller can safely retry the whole payload.
  def upsert_records(records_data)
    accepted = 0

    StepRecord.transaction do
      records_data.each do |entry|
        recorded_on = parse_recorded_on(entry["recorded_on"])

        record = StepRecord.find_or_initialize_by(user: @webhook_user, recorded_on: recorded_on)

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

  # Record audit log entry. Uses keyword argument `user:` so callers can
  # override with nil for unauthorized cases where @webhook_user is unreliable.
  # accepted_count: Issue #52 で追加。何件保存されたかを記録、success 時の中身が空ペイロードかを後追い分析可能にする。
  def record_delivery!(status:, accepted_count: nil, error_message: nil, user: @webhook_user)
    # Attempt to parse stored body as JSON for richer inspection in the audit log.
    # Falls back to { raw: <string> } when the body is not valid JSON.
    payload = begin
      JSON.parse(@raw_body)
    rescue JSON::ParserError
      { raw: @raw_body.truncate(500) }
    end

    WebhookDelivery.create!(
      user: user,
      payload: payload,
      status: status,
      accepted_count: accepted_count,
      error_message: error_message,
      received_at: Time.current
    )
  rescue ActiveRecord::RecordInvalid => e
    # Non-fatal: delivery logging must not crash the main response path.
    Rails.logger.error("[WebhooksController] Failed to save WebhookDelivery: #{e.message}")
  end
end
