class SessionsController < ApplicationController
  def create
    auth = request.env["omniauth.auth"]
    if auth.nil?
      Rails.logger.error("OAuth login failed: omniauth.auth is nil")
      return redirect_to root_path, alert: "ログインに失敗しました"
    end

    user = User.from_omniauth(auth)
    reset_session
    session[:user_id] = user.id
    redirect_to root_path, notice: "ログインしました"
  rescue ActiveRecord::RecordInvalid => e
    Rails.logger.error("OAuth login failed: #{e.message}")
    redirect_to root_path, alert: "ログインに失敗しました"
  end

  def destroy
    reset_session
    redirect_to root_path, notice: "ログアウトしました"
  end

  def failure
    redirect_to root_path, alert: "ログインに失敗しました"
  end
end
