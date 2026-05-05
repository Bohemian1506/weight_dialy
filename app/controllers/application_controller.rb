class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  # Capacitor アプリの WebView は UA に "wv" が付く Android System WebView ベースで modern 判定から弾かれる。
  # capacitor.config.json で android.appendUserAgent="WeightDialyCapacitor" を付与し、ここで bypass する。
  # (= Web 版には影響なし、Capacitor からの request のみ allow)
  allow_browser versions: :modern,
                if: -> { !request.user_agent.to_s.include?("WeightDialyCapacitor") }

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
