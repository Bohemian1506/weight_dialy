class WebhooksController < ActionController::API
  # API クライアント (Apple Shortcuts / curl) からの呼び出し専用エンドポイント。
  # ActionController::API 継承は Rails 標準の API-only パターンで、CSRF 保護 / browser check / cookie /
  # session を含まない (skip_forgery_protection 等の禁止 workaround とは別物 — そもそも入っていない)。
  # 認証は Bearer token (authenticate_webhook!) で行う。
  #
  # ドメインロジック (= ペイロード検証 + パース + 永続化) は WebhookHealthDataIngestService に切り出し済
  # (= ダッシュボード Tier 2 #4、refactor-candidates.md 由来、fat controller 解消の教材ポイント)。
  # controller は **HTTP の入出力 + 認証 + 監査ログ** に専念する。

  before_action :read_raw_body
  before_action :authenticate_webhook!

  def health_data
    parsed = JSON.parse(@raw_body)
    accepted = WebhookHealthDataIngestService.call(records_data: parsed["records"], user: @webhook_user)
    record_delivery!(status: "success", accepted_count: accepted)
    render json: { accepted: accepted }, status: :ok
  rescue JSON::ParserError => e
    Rails.logger.warn("[WebhooksController] JSON parse error: #{e.message.truncate(120)}")
    record_delivery!(status: "invalid", accepted_count: 0, error_message: I18n.t("webhook.errors.json_parse_error"))
    render json: { error: "Invalid payload" }, status: :unprocessable_content
  rescue WebhookHealthDataIngestService::InvalidPayload => e
    record_delivery!(status: "invalid", accepted_count: 0, error_message: e.message.truncate(120))
    render json: { error: "Invalid payload" }, status: :unprocessable_content
  rescue ActiveRecord::RecordInvalid => e
    # 個々のレコードのバリデーション違反 (負数 / 不正な日付等) を 500 ではなく 422 + 監査ログで返す。
    # rails-implementer の意図 (全体失敗方式) を実装まで貫徹するため。
    Rails.logger.warn("[WebhooksController] RecordInvalid: #{e.message.truncate(120)}")
    record_delivery!(status: "invalid", accepted_count: 0, error_message: I18n.t("webhook.errors.record_invalid"))
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
    record_delivery!(status: "unauthorized", error_message: I18n.t("webhook.errors.unauthorized"), user: nil)
    render json: { error: "Unauthorized" }, status: :unauthorized and return
  end

  def extract_bearer_token
    request.headers["Authorization"]&.delete_prefix("Bearer ")&.strip
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
