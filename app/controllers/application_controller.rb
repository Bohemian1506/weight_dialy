class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  # 二重防衛 (= Phase 3 完成 PR #149-#154 で「主軸 + 保険 1」体制に縮小、cleanup PR #175):
  # - 主軸: Capacitor の overrideUserAgent で "WeightDialyCapacitor" 付与 → サーバー側で識別
  # - 保険 1: Android System WebView (UA に "; wv)") → overrideUserAgent が壊れた場合のフォールバック
  #
  # /auth/ パス + /auto_login は早期リターンで modern check 完全スキップ (= OAuth Custom Tabs 経路 + Phase 3 token 経路の保険)。
  #
  # 旧「保険 2: Mobile Chrome bypass」は PR #175 で削除 (= Phase 3 deep link 完成 = PR #149-#154 で custom URL scheme + one-time token 完成 → OAuth Custom Tabs から戻った後の遷移問題が解消、
  # Web 版モバイル Chrome を bypass しない本来挙動に復帰)。
  allow_browser versions: :modern,
                if: -> {
                  next false if request.path.start_with?("/auth/")
                  next false if request.path == "/auto_login" # Phase 3: overrideUserAgent 剥落時でも token 経路は素通しさせる保険
                  ua = request.user_agent.to_s
                  next false if ua.include?("WeightDialyCapacitor")              # 主軸: Capacitor 識別
                  next false if ua.include?("; wv)")                             # 保険 1: Android WebView
                  true
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
