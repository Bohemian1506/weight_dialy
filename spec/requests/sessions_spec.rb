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

  describe "GET /auth/failure" do
    it "redirects to root_path" do
      get auth_failure_path
      expect(response).to redirect_to(root_path)
    end

    it "sets an alert flash" do
      get auth_failure_path
      expect(flash[:alert]).to eq("ログインに失敗しました")
    end
  end
end
