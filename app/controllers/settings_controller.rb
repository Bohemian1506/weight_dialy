class SettingsController < ApplicationController
  before_action :require_login

  def show
    @webhook_token = current_user.webhook_token
    # _url ヘルパは request 由来で絶対 URL を組み立てるため、host 引数は不要 (二重指定リスク回避)。
    # 本番デプロイ時は config.action_controller.default_url_options or config.hosts でホスト解決を制御する。
    @webhook_url = webhooks_health_data_url
  end

  def regenerate_token
    current_user.regenerate_webhook_token
    redirect_to settings_path, notice: "Webhook トークンを再生成しました。Apple Shortcuts 側の設定も更新してください。"
  rescue ActiveRecord::ActiveRecordError
    # has_secure_token の uniqueness 衝突 / DB 接続エラー等の保険。発表会前の安全策。
    redirect_to settings_path, alert: "再生成に失敗しました。時間をおいて再度お試しください。"
  end
end
