require "rails_helper"

# navbar の表示内容を担保する request spec (Issue #174 D)。
# A (scroll shadow) / B (CSS 変数) は visual な挙動のため request spec では検証しない。
# 案 A (= 未ログイン navbar CTA を削除して banner_guest に集約) 後の検証に書き換え済。
RSpec.describe "Navbar", type: :request do
  # response.body から <header>...</header> 部分だけ抽出するヘルパー (= navbar 単体の確認用)。
  def header_html(body)
    body.match(%r{<header[^>]*>.*?</header>}m)&.[](0).to_s
  end

  describe "GET /" do
    context "未ログイン時" do
      before { get root_path }

      it "ホームページに Google ログインボタンが含まれる (= banner_guest 由来、案 A で navbar から banner に集約)" do
        expect(response.body).to include("/auth/google_oauth2")
        expect(response.body).to include("Google でログイン")
      end

      it "navbar 単体には未ログイン CTA を含まない (= 案 A 反映、認知負荷回避)" do
        nav = header_html(response.body)
        expect(nav).not_to include("/auth/google_oauth2")
        expect(nav).not_to include("ログイン")
      end

      it "「設定」リンクを含まない (= ログイン時専用 navbar アイテム)" do
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
