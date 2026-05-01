class WebhooksController < ActionController::API
  # API クライアント (Apple Shortcuts / curl) からの呼び出し専用エンドポイント。
  # ActionController::API 継承は Rails 標準の API-only パターンで、CSRF 保護 / browser check / cookie /
  # session を含まない (skip_forgery_protection 等の禁止 workaround とは別物 — そもそも入っていない)。
  # 認証は Bearer token (authenticate_webhook!) で行う。
  before_action :read_raw_body
  before_action :authenticate_webhook!

  def health_data
    parsed = JSON.parse(@raw_body)
    records_data = parsed["records"]

    unless records_data.is_a?(Array)
      record_delivery!(status: "invalid", error_message: "missing 'records' array")
      render json: { error: "Invalid payload" }, status: :unprocessable_content
      return
    end

    accepted = upsert_records(records_data)
    record_delivery!(status: "success")
    render json: { accepted: accepted }, status: :ok
  rescue JSON::ParserError => e
    record_delivery!(status: "invalid", error_message: "JSON parse error: #{e.message.truncate(120)}")
    render json: { error: "Invalid payload" }, status: :unprocessable_content
  rescue ActiveRecord::RecordInvalid => e
    # 個々のレコードのバリデーション違反 (負数 / 不正な日付等) を 500 ではなく 422 + 監査ログで返す。
    # rails-implementer の意図 (全体失敗方式) を実装まで貫徹するため。
    record_delivery!(status: "invalid", error_message: "RecordInvalid: #{e.message.truncate(120)}")
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

  # Upsert each day's record, updating only the keys present in the payload.
  # Keys absent from the payload are left unchanged (partial-update semantics).
  # All-or-nothing: wrap in a transaction so that if any record fails validation
  # the entire batch rolls back and the caller can safely retry the whole payload.
  def upsert_records(records_data)
    accepted = 0

    StepRecord.transaction do
      records_data.each do |entry|
        recorded_on = entry["recorded_on"]
        next if recorded_on.blank?

        record = StepRecord.find_or_initialize_by(user: @webhook_user, recorded_on: recorded_on)

        # Slice only the keys the caller sent; compact removes nils so that
        # missing keys do not overwrite existing values with nil/0.
        # NOTE: we cannot distinguish "key absent" from "explicit 0" because both
        # arrive as falsy in JSON; partial-update semantics treat absent ≠ 0.
        updates = {
          steps:           entry["steps"],
          distance_meters: entry["distance_meters"],
          flights_climbed: entry["flights_climbed"]
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
  def record_delivery!(status:, error_message: nil, user: @webhook_user)
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
      error_message: error_message,
      received_at: Time.current
    )
  rescue ActiveRecord::RecordInvalid => e
    # Non-fatal: delivery logging must not crash the main response path.
    Rails.logger.error("[WebhooksController] Failed to save WebhookDelivery: #{e.message}")
  end
end
