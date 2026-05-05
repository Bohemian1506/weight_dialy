class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  # 三重防衛 (= 子 6 動作確認の連鎖発覚で段階的に拡張: PR #140 → #142 → #146 → 本 PR):
  # - 主軸: Capacitor の overrideUserAgent で "WeightDialyCapacitor" 付与 → サーバー側で識別
  # - 保険 1: Android System WebView (UA に "; wv)") → overrideUserAgent が壊れた場合のフォールバック
  # - 保険 2: Mobile Chrome (UA に Chrome/N + Mobile) → OAuth Custom Tabs から戻った後の / 遷移で UA が変わる対策
  #
  # /auth/ パスは早期リターンで modern check 完全スキップ (= Google In-App Browsers Are Not Allowed 2021)。
  #
  # 副作用: Mobile Chrome bypass で Web 版モバイル Chrome ユーザーも全て通る。
  # ただし allow_browser はそもそもセキュリティ機能ではなく「古い IE / Firefox / 旧 Safari を弾く UX 防御」目的のため、
  # Mobile Chrome 系を緩めても本来意図 (PC 古いブラウザ排除) は維持される。発表会前応急対応として許容。
  # 根本解決 (= Capacitor の deep link / app links で OAuth 後 Capacitor アプリに戻す) は v1.1 で対応予定。
  allow_browser versions: :modern,
                if: -> {
                  next false if request.path.start_with?("/auth/")
                  ua = request.user_agent.to_s
                  next false if ua.include?("WeightDialyCapacitor")              # 主軸: Capacitor 識別
                  next false if ua.include?("; wv)")                             # 保険 1: Android WebView
                  next false if ua.match?(/Chrome\/\d+/) && ua.include?("Mobile") # 保険 2: Mobile Chrome (Custom Tabs / 通常 Mobile Chrome)
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
