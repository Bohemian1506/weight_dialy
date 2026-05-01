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
        expect(response.body).to include("ようこそ、#{user.name}さん。")
      end

      it "ホーム本体の Google でログインボタンを表示しない" do
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
