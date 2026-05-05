class SessionsController < ApplicationController
  # Phase 3 Capacitor OAuth ブリッジの起点。Custom Tabs (= @capacitor/browser 経由) から GET で叩かれる。
  # ここで Custom Tabs cookie に capacitor_oauth フラグを焼き、view 側で /auth/google_oauth2 に自動 POST する。
  # Custom Tabs と Capacitor WebView は cookie storage が分離しているため、後段 sessions#create で
  # 「これは Capacitor 由来の OAuth」と判別する唯一の手段がこの session フラグになる。
  layout false, only: :capacitor_start

  def capacitor_start
    session[:capacitor_oauth] = true
  end

  def create
    auth = request.env["omniauth.auth"]
    if auth.nil?
      Rails.logger.error("OAuth login failed: omniauth.auth is nil")
      return redirect_to root_path, alert: "ログインに失敗しました。もう一度お試しください"
    end

    user = User.from_omniauth(auth)
    capacitor_oauth = session.delete(:capacitor_oauth)

    if capacitor_oauth
      # Capacitor 由来: Custom Tabs cookie storage に session を作っても WebView 側からは読めないため、
      # one-time token を発行 → custom URL scheme で Capacitor アプリへ転送 → WebView 側 /auto_login で消費して session 確立、というブリッジを組む。
      ott = OneTimeLoginToken.issue!(user: user)
      reset_session # Custom Tabs 側 session に残骸を残さない (= ブリッジ完了後は WebView 側 session のみが正)
      Rails.logger.info("OAuth login completed via Capacitor bridge (user_id=#{user.id})")
      redirect_to "com.weightdialy.app://oauth_callback?token=#{ott.token}",
                  allow_other_host: true
    else
      # 通常 Web 経由: 従来通り Rails session を直接張る
      reset_session
      session[:user_id] = user.id
      Rails.logger.info("OAuth login completed via web (user_id=#{user.id})")
      redirect_to root_path, notice: "ログインしました"
    end
  rescue ActiveRecord::RecordInvalid => e
    Rails.logger.error("OAuth login failed: #{e.message}")
    redirect_to root_path, alert: "ログインに失敗しました。もう一度お試しください"
  end

  # Capacitor WebView 側の入口。custom scheme で受け取った one-time token を消費し、WebView cookie storage に session を確立する。
  # token は単独で完結し外部から漏れても 30 秒 + 1 回限りで失効するが、念のため reset_session で session fixation を排除。
  def auto_login
    token = OneTimeLoginToken.consume!(token: params[:token].to_s)
    if token.nil?
      Rails.logger.warn("auto_login rejected: invalid/expired/used token")
      return redirect_to root_path, alert: "ログインの確認に失敗しました。もう一度お試しください"
    end

    reset_session
    session[:user_id] = token.user_id
    redirect_to root_path, notice: "ログインしました"
  end

  def destroy
    reset_session
    redirect_to root_path, notice: "ログアウトしました"
  end

  def failure
    # OAuth フロー中断 (= ユーザーがキャンセル / Custom Tabs から戻った等) の専用文言
    redirect_to root_path, alert: "Google ログインがキャンセルされました。再度お試しください"
  end
end
