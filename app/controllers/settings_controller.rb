class SettingsController < ApplicationController
  before_action :require_login

  def show
    @webhook_token = current_user.webhook_token
    @webhook_url = webhooks_health_data_url(host: request.base_url)
  end

  def regenerate_token
    current_user.regenerate_webhook_token
    redirect_to settings_path, notice: "Webhook トークンを再生成しました。Apple Shortcuts 側の設定も更新してください。"
  end
end
