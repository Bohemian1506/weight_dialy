require "rails_helper"

# navbar の表示内容を担保する request spec (Issue #174 D)。
# A (scroll shadow) / B (CSS 変数) は visual な挙動のため request spec では検証しない。
# D (未ログイン時 navbar CTA) を中心に、ログイン時との分岐を確認する。
RSpec.describe "Navbar", type: :request do
  describe "GET /" do
    context "未ログイン時" do
      before { get root_path }

      it "navbar 内にログインボタン (CTA) が含まれる" do
        # button_to で生成される form action に /auth/google_oauth2 が含まれる
        expect(response.body).to include("/auth/google_oauth2")
      end

      it "navbar 内に sketch-btn-primary クラスのボタンが含まれる" do
        expect(response.body).to include("sketch-btn-primary")
      end

      it "「ログイン」文言が含まれる" do
        expect(response.body).to include("ログイン")
      end

      it "「設定」リンクを含まない" do
        # ログイン時専用の navbar アイテムが未ログイン時に露出しないことを確認
        expect(response.body).not_to include(">設定<")
      end

      it "「ログアウト」ボタンを含まない" do
        expect(response.body).not_to include("ログアウト")
      end
    end

    context "ログイン済み時" do
      let(:user) { create(:user) }

      before do
        mock_google_oauth2(uid: user.uid, email: user.email, name: user.name)
        get auth_callback_path(provider: "google_oauth2")
        get root_path
      end

      it "navbar 内にユーザー名が含まれる" do
        expect(response.body).to include(user.name)
      end

      it "「設定」リンクが含まれる" do
        expect(response.body).to include("設定")
      end

      it "「ログアウト」ボタンが含まれる" do
        expect(response.body).to include("ログアウト")
      end

      it "未ログイン時の navbar CTA (capacitor-oauth-login コンテナ) を含まない" do
        # 未ログイン用の div[data-controller="capacitor-oauth-login"] が navbar に出ないことを確認。
        # banner_guest は表示されないため response.body に capacitor-oauth-login が残る場合は navbar 由来。
        # ログイン済みでは banner_guest 自体も非表示なので、capacitor-oauth-login は完全に出ないはず。
        expect(response.body).not_to include("capacitor-oauth-login")
      end
    end
  end
end
