require 'rails_helper'

RSpec.describe "Home", type: :request do
  describe "GET /" do
    context "未ログイン時" do
      before { get root_path }

      it "200 OK を返す" do
        expect(response).to have_http_status(:ok)
      end

      it "Google でログインボタンを表示する" do
        expect(response.body).to include("Google でログイン")
      end

      it "ようこそメッセージを表示しない" do
        expect(response.body).not_to include("ようこそ")
      end

      it "過去のダミーバッジ文字列を含まない" do
        expect(response.body).not_to include("Day 1: daisyUI 動作確認")
      end

      # 過去のダミーボタン (Primary / Secondary / Accent) の回帰防止:
      # button_to が生成する <button>...</button> のボタンテキストとして
      # 該当文字列が現れないことを `>Primary<` のような囲い文字で検証する
      it "旧ダミーボタン Primary を含まない" do
        expect(response.body).not_to include(">Primary<")
      end

      it "旧ダミーボタン Secondary を含まない" do
        expect(response.body).not_to include(">Secondary<")
      end

      it "旧ダミーボタン Accent を含まない" do
        expect(response.body).not_to include(">Accent<")
      end
    end

    context "ログイン時" do
      let(:user) { create(:user) }

      before do
        mock_google_oauth2(uid: user.uid, email: user.email, name: user.name)
        get auth_callback_path(provider: "google_oauth2")
        get root_path
      end

      it "200 OK を返す" do
        expect(response).to have_http_status(:ok)
      end

      it "ようこそメッセージにユーザー名を含む" do
        # PR #30 (sketchy 化) で <b>name</b> でラップ + 半角スペース挿入する形に変更されたため、
        # 文字列完全一致ではなく構成要素を独立して検証する。
        expect(response.body).to include("ようこそ、")
        expect(response.body).to include(user.name)
      end

      it "Google でログインボタンをどこにも表示しない" do
        expect(response.body).not_to include("Google でログイン")
      end

      it "ヘッダにユーザー名を表示する" do
        expect(response.body).to include(user.name)
      end

      it "ヘッダにログアウトボタンを表示する" do
        expect(response.body).to include("ログアウト")
      end
    end
  end
end
