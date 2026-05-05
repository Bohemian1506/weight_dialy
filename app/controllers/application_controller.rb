class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  # Capacitor アプリの WebView は UA に "wv" が付く Android System WebView ベースで modern 判定から弾かれる。
  # bypass 二重防衛 (= 学び 17 / Capacitor appendUserAgent バグ #4886 #6037 既知の沼を踏んだため):
  # - Capacitor 側: capacitor.config.json android.overrideUserAgent で UA に "WeightDialyCapacitor" を付与 (= 主軸)
  # - Rails 側 1: UA に "WeightDialyCapacitor" を含む → bypass (= Capacitor 経由を識別)
  # - Rails 側 2: UA に "; wv)" を含む → bypass (= Android WebView 全般、保険、SNS 内蔵ブラウザは Chrome 120+ 系で modern check 通過予定なので影響軽微)
  allow_browser versions: :modern,
                if: -> {
                  ua = request.user_agent.to_s
                  !ua.include?("WeightDialyCapacitor") && !ua.include?("; wv)")
                }

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  helper_method :current_user, :logged_in?

  private

  def current_user
    return @current_user if instance_variable_defined?(:@current_user)
    @current_user = session[:user_id] ? User.find_by(id: session[:user_id]) : nil
  end

  def logged_in?
    current_user.present?
  end

  def require_login
    return if logged_in?

    redirect_to root_path, alert: "ログインが必要です"
  end
end
