module Account
  class DeletionsController < ApplicationController
    before_action :require_login

    def destroy
      user = current_user
      user_id = user.id
      email = user.email

      Rails.logger.info "[UserDeletion] user_id=#{user_id} email=#{email} deleted_at=#{Time.current.iso8601}"

      user.destroy!

      reset_session
      redirect_to root_path, notice: "退会完了しました。ご利用ありがとうございました。"
    end
  end
end
