module Account
  class DeletionsController < ApplicationController
    before_action :require_login

    def destroy
      user = current_user
      user_id = user.id
      user.destroy!
      Rails.logger.info "[UserDeletion] user_id=#{user_id} deleted_at=#{Time.current.iso8601}"
      reset_session
      redirect_to root_path, notice: "退会完了しました。またいつでも歩いた日には使ってください。"
    rescue ActiveRecord::RecordNotDestroyed => e
      Rails.logger.error "[UserDeletion] failed user_id=#{user_id} error=#{e.message}"
      redirect_to settings_path, alert: "退会処理に失敗しました。しばらく経ってから再度お試しください。"
    end
  end
end
