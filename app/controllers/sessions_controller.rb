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
      bridge_to_capacitor(user)
    else
      Rails.logger.info("OAuth login completed via web (user_id=#{user.id})")
      establish_session_and_redirect_home(user.id)
    end
  rescue ActiveRecord::RecordInvalid => e
    Rails.logger.error("OAuth login failed: #{e.message}")
    redirect_to root_path, alert: "ログインに失敗しました。もう一度お試しください"
  end

  # Capacitor WebView 側の入口。custom scheme で受け取った one-time token を消費し、WebView cookie storage に session を確立する。
  # token は単独で完結し外部から漏れても 30 秒 + 1 回限りで失効するが、念のため reset_session で session fixation を排除。
  def auto_login
    response.headers["Cache-Control"] = "no-store" # Turbo Drive prefetch 予防 (= 将来 link_to が増えた時に token を意図せず消費されないように)
    token = OneTimeLoginToken.consume!(token: params[:token].to_s)
    if token.nil?
      Rails.logger.warn("auto_login rejected: invalid/expired/used token")
      return redirect_to root_path, alert: "ログインの確認に失敗しました。もう一度お試しください"
    end

    Rails.logger.info("auto_login completed via Capacitor WebView (user_id=#{token.user_id})")
    establish_session_and_redirect_home(token.user_id)
  end

  def destroy
    reset_session
    redirect_to root_path, notice: "ログアウトしました"
  end

  def failure
    # OAuth フロー中断 (= ユーザーがキャンセル / Custom Tabs から戻った等) の専用文言
    redirect_to root_path, alert: "Google ログインがキャンセルされました。再度お試しください"
  end

  private

  # 通常 Web 経由 OAuth (= sessions#create) と Capacitor token 消費 (= sessions#auto_login) の
  # ログイン後 session 確立を共通化。session fixation 排除のため reset_session を必ず噛ませる。
  #
  # なぜ Concern でなく private method か (= Issue #228 教材ポイント、4 観点で機械的に判定):
  #   1. 共有相手: 同一コントローラ内 2 箇所のみ → Concern (= 複数コントローラ間共有用) は過剰抽象化
  #   2. 重複粒度: 3 行 × 2 箇所、private メソッド 1 個で十分解消可能
  #   3. CLAUDE.md「過剰な抽象化 / DRY (3 回出てから抽象化)」 の適用粒度:
  #      ここでの「抽象化」 は Concern / 基底クラス / DSL 等の **構造的分離** に対する制約。
  #      同一クラス内 private 抽出は「整理」 に該当するため 2 箇所でも抽出可。
  #   4. テスタビリティ: 3 行 / redirect のみ → request spec で十分カバー、独立 unit test 不要 → Concern にする動機なし
  #   → Rails 慣習: 同一コントローラ内重複は private、複数コントローラ間重複は Concern
  #
  # logger.info は呼び出し側に残置 (= 「OAuth web 経由」 と「Capacitor token 消費」 の文脈差を
  # 各経路で明示するため、共通化すると経路が読めなくなる)。
  def establish_session_and_redirect_home(user_id)
    reset_session
    session[:user_id] = user_id
    redirect_to root_path, notice: "ログインしました"
  end

  # Capacitor 由来 OAuth callback の処理を create から切り出した private。
  # Custom Tabs cookie storage は WebView 側から読めないため、one-time token を発行 → custom URL scheme で
  # Capacitor アプリへ転送 → WebView 側 /auto_login で消費して session 確立、というブリッジを組む。
  #
  # ここでは establish_session_and_redirect_home を呼ばない (= session を張って root_path に飛ばすメソッドのため、
  # Capacitor 経路では session 確立せず custom URL scheme へ転送する必要があり、共通化すると壊れる)。
  # reset_session で Custom Tabs 側 session に残骸を残さない (= ブリッジ完了後は WebView 側 session のみが正)。
  def bridge_to_capacitor(user)
    ott = OneTimeLoginToken.issue!(user: user)
    reset_session
    Rails.logger.info("OAuth login completed via Capacitor bridge (user_id=#{user.id})")
    redirect_to "com.weightdialy.app://oauth_callback?token=#{ott.token}",
                allow_other_host: true
  end
end
