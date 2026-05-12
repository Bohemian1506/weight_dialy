require 'rails_helper'

RSpec.describe "Sessions", type: :request do
  describe "GET /auth/google_oauth2/callback" do
    context "when OAuth succeeds with a new user" do
      before { mock_google_oauth2(uid: "new_uid_1", email: "newuser@example.com", name: "New User") }

      it "creates a user record" do
        expect { get auth_callback_path(provider: "google_oauth2") }.to change(User, :count).by(1)
      end

      it "stores the user id in the session" do
        get auth_callback_path(provider: "google_oauth2")
        expect(session[:user_id]).to eq(User.last.id)
      end

      it "redirects to root_path" do
        get auth_callback_path(provider: "google_oauth2")
        expect(response).to redirect_to(root_path)
      end

      it "sets a notice flash" do
        get auth_callback_path(provider: "google_oauth2")
        expect(flash[:notice]).to eq("ログインしました")
      end
    end

    context "when the user already exists" do
      before do
        create(:user, provider: "google_oauth2", uid: "existing_uid")
        mock_google_oauth2(uid: "existing_uid", email: "existing@example.com", name: "Existing User")
      end

      it "does not create a new user record" do
        expect { get auth_callback_path(provider: "google_oauth2") }.not_to change(User, :count)
      end
    end
  end

  describe "DELETE /logout" do
    # session を直接 set するために logged-in 状態を作る
    let(:user) { create(:user) }

    before do
      # request spec では get でセッションを作ってから logout するのが自然だが、
      # セッション注入ヘルパーがないため、ログイン callback 経由で session を張る
      mock_google_oauth2(uid: user.uid, email: user.email, name: user.name)
      get auth_callback_path(provider: "google_oauth2")
    end

    it "clears the user session" do
      delete logout_path
      expect(session[:user_id]).to be_nil
    end

    it "redirects to root_path" do
      delete logout_path
      expect(response).to redirect_to(root_path)
    end

    it "sets a notice flash" do
      delete logout_path
      expect(flash[:notice]).to eq("ログアウトしました")
    end
  end

  describe "GET /auth/capacitor_start (Phase 3 OAuth ブリッジ起点)" do
    it "renders the bridge page with auto-submit form to /auth/google_oauth2" do
      get capacitor_oauth_start_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Google ログインへ進んでいます")
      expect(response.body).to include('action="/auth/google_oauth2"')
      expect(response.body).to include('method="post"')
      # 自動 submit 用 script
      expect(response.body).to include("capacitor-oauth-bridge")
      expect(response.body).to include(".submit()")
    end

    it "renders without the application layout" do
      get capacitor_oauth_start_path
      # application layout 固有のマーカー (navbar / footer 等) を含まないことを担保
      expect(response.body).not_to include('class="sketch-navbar"')
    end

    it "marks the session as capacitor_oauth = true" do
      get capacitor_oauth_start_path
      expect(session[:capacitor_oauth]).to be(true)
    end

    it "includes CSRF authenticity token under production-like forgery protection (= OmniAuth POST 必須)" do
      original = ActionController::Base.allow_forgery_protection
      ActionController::Base.allow_forgery_protection = true
      begin
        get capacitor_oauth_start_path
        expect(response.body).to match(/name="authenticity_token"/)
      ensure
        ActionController::Base.allow_forgery_protection = original
      end
    end
  end

  describe "GET /auth/google_oauth2/callback (Phase 3 capacitor_oauth フラグあり)" do
    before do
      mock_google_oauth2(uid: "capacitor_uid_1", email: "capacitor@example.com", name: "Capacitor User")
      # Custom Tabs cookie に capacitor_oauth フラグが乗っている状態を再現
      get capacitor_oauth_start_path
    end

    it "issues a one-time token" do
      expect { get auth_callback_path(provider: "google_oauth2") }.to change(OneTimeLoginToken, :count).by(1)
    end

    it "redirects to the custom URL scheme with token" do
      get auth_callback_path(provider: "google_oauth2")
      issued = OneTimeLoginToken.last
      expect(response).to redirect_to("com.weightdialy.app://oauth_callback?token=#{issued.token}")
    end

    it "does NOT set session[:user_id] in the Custom Tabs cookie storage" do
      # Custom Tabs 側 session には残さない (= reset_session)。WebView 側 /auto_login で改めて確立。
      get auth_callback_path(provider: "google_oauth2")
      expect(session[:user_id]).to be_nil
    end

    it "clears the capacitor_oauth flag after consuming" do
      get auth_callback_path(provider: "google_oauth2")
      expect(session[:capacitor_oauth]).to be_nil
    end
  end

  describe "GET /auto_login (Phase 3 WebView 側 token 消費)" do
    let(:user) { create(:user) }

    context "with a valid live token" do
      let!(:token_record) { OneTimeLoginToken.issue!(user: user) }

      it "consumes the token" do
        get auto_login_path(token: token_record.token)
        expect(token_record.reload.used?).to be(true)
      end

      it "stores the user id in the WebView session" do
        get auto_login_path(token: token_record.token)
        expect(session[:user_id]).to eq(user.id)
      end

      it "redirects to root_path" do
        get auto_login_path(token: token_record.token)
        expect(response).to redirect_to(root_path)
      end

      it "sets a notice flash" do
        get auto_login_path(token: token_record.token)
        expect(flash[:notice]).to eq("ログインしました")
      end

      it "sets Cache-Control: no-store to prevent token URL caching" do
        get auto_login_path(token: token_record.token)
        expect(response.headers["Cache-Control"]).to eq("no-store")
      end
    end

    context "with an expired token" do
      let!(:token_record) { create(:one_time_login_token, :expired, user: user) }

      it "does not log the user in" do
        get auto_login_path(token: token_record.token)
        expect(session[:user_id]).to be_nil
        expect(flash[:alert]).to eq("ログインの確認に失敗しました。もう一度お試しください")
      end
    end

    context "with an already-used token (= replay 防止)" do
      let!(:token_record) { create(:one_time_login_token, :used, user: user) }

      it "does not log the user in" do
        get auto_login_path(token: token_record.token)
        expect(session[:user_id]).to be_nil
      end
    end

    context "with an unknown token" do
      it "does not log the user in" do
        get auto_login_path(token: "nonexistent_xxx")
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq("ログインの確認に失敗しました。もう一度お試しください")
      end
    end
  end

  describe "GET /auth/failure" do
    it "redirects to root_path" do
      get auth_failure_path
      expect(response).to redirect_to(root_path)
    end

    it "sets an alert flash with cancellation guidance" do
      # PR #146 design レビューで OAuth 中断専用文言に変更 (= 通常失敗とは別、Custom Tabs 復帰時の UX 改善)
      get auth_failure_path
      expect(flash[:alert]).to eq("Google ログインがキャンセルされました。再度お試しください")
    end
  end
end
