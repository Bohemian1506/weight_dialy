class SessionsController < ApplicationController
  def create
    user = User.from_omniauth(request.env["omniauth.auth"])
    session[:user_id] = user.id
    redirect_to root_path, notice: "ログインしました"
  rescue ActiveRecord::RecordInvalid => e
    Rails.logger.error("OAuth login failed: #{e.message}")
    redirect_to root_path, alert: "ログインに失敗しました"
  end

  def destroy
    session.delete(:user_id)
    redirect_to root_path, notice: "ログアウトしました"
  end

  def failure
    redirect_to root_path, alert: "ログインに失敗しました"
  end
end
