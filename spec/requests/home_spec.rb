require "rails_helper"

RSpec.describe "Home", type: :request do
  # UA 定数
  # allow_browser versions: :modern は Safari 17.2+ を要求するため、
  # iOS テスト UA も Version/17.2 を明示する必要がある。
  iphone_ua = "Mozilla/5.0 (iPhone; CPU iPhone OS 17_2 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.2 Mobile/15E148 Safari/604.1"
  android_ua = "Mozilla/5.0 (Linux; Android 14; Pixel 8) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36"

  # ログインヘルパー: OmniAuth モックでセッションを確立する
  def login_as(user)
    mock_google_oauth2(uid: user.uid, email: user.email, name: user.name)
    get auth_callback_path(provider: "google_oauth2")
  end

  # バナー render の共通検証
  shared_examples "banner_guest が表示される" do
    it "「これはサンプルデータです」を含む" do
      expect(response.body).to include("これは")
      expect(response.body).to include("サンプルデータ")
    end
  end

  shared_examples "banner_android が表示される" do
    it "「Android 版は現在開発中」を含む" do
      expect(response.body).to include("Android 版")
      expect(response.body).to include("現在開発中")
    end
  end

  shared_examples "banner_empty が表示される" do
    it "「Apple Shortcuts を設定」を含む" do
      expect(response.body).to include("Apple Shortcuts")
      expect(response.body).to include("設定")
    end
  end

  shared_examples "状態別バナーが一切ない" do
    it "banner_guest を含まない" do
      expect(response.body).not_to include("これはサンプルデータ")
    end

    it "banner_android を含まない" do
      expect(response.body).not_to include("Android 版")
    end

    it "banner_empty を含まない" do
      expect(response.body).not_to include("sketch-banner-empty")
    end
  end

  describe "GET /" do
    # ─────────────────────────────────────────────────
    # 状態 :guest — 未ログイン
    # ─────────────────────────────────────────────────
    context "状態 :guest (未ログイン)" do
      before { get root_path }

      it "200 OK を返す" do
        expect(response).to have_http_status(:ok)
      end

      include_examples "banner_guest が表示される"

      it "dashboard の sketch-topbar を含む" do
        expect(response.body).to include("sketch-topbar")
      end

      it "dashboard の sketch-chart-svg を含む" do
        expect(response.body).to include("sketch-chart-svg")
      end

      it "表示名がデフォルト「ユウキ」である" do
        expect(response.body).to include("ユウキ")
      end

      it "Google でログインボタンを表示する" do
        expect(response.body).to include("Google でログイン")
      end

      # 過去のダミーコンテンツ回帰防止
      it "旧ダミーバッジ文字列を含まない" do
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

    # ─────────────────────────────────────────────────
    # 状態 :android — ログイン済み + Android UA
    # ─────────────────────────────────────────────────
    context "状態 :android (ログイン済み + Android UA)" do
      let(:user) { create(:user) }

      before do
        login_as(user)
        get root_path, headers: { "User-Agent" => android_ua }
      end

      it "200 OK を返す" do
        expect(response).to have_http_status(:ok)
      end

      include_examples "banner_android が表示される"

      it "表示名が current_user.name である" do
        expect(response.body).to include(user.name)
      end

      it "Google でログインボタンをどこにも表示しない" do
        expect(response.body).not_to include("Google でログイン")
      end

      it "ログアウトボタンを表示する" do
        expect(response.body).to include("ログアウト")
      end
    end

    # ─────────────────────────────────────────────────
    # 状態 :iphone_with_data — ログイン済み + iOS UA + データあり
    # ─────────────────────────────────────────────────
    context "状態 :iphone_with_data (ログイン済み + iPhone UA + step_records あり)" do
      let(:user) { create(:user) }
      let!(:step_record) do
        create(:step_record, user: user, recorded_on: Date.current, steps: 9000)
      end

      before do
        login_as(user)
        get root_path, headers: { "User-Agent" => iphone_ua }
      end

      it "200 OK を返す" do
        expect(response).to have_http_status(:ok)
      end

      include_examples "状態別バナーが一切ない"

      it "表示名が current_user.name である" do
        expect(response.body).to include(user.name)
      end

      it "ログアウトボタンを表示する" do
        expect(response.body).to include("ログアウト")
      end

      # 貯カロリー (Issue #41): 9000 歩 * 0.04 = 360 kcal
      it "「今月の貯カロリー」見出しを表示する" do
        expect(response.body).to include("今月の貯カロリー")
      end

      it "貯カロリーのメイン数値 (sketch-savings-main) を描画する" do
        expect(response.body).to include("sketch-savings-main")
      end

      it "今月の貯カロリー値 360 kcal を含む (= 9000 歩 * 0.04 を四捨五入で number_with_delimiter)" do
        expect(response.body).to include("360")
      end

      it "累計表示「これまでの合計:」の文言を含む (= カジュアル層配慮、design-reviewer 指摘)" do
        expect(response.body).to include("これまでの合計:")
      end
    end

    # ─────────────────────────────────────────────────
    # 状態 :empty — ログイン済み + iOS UA + データなし
    # ─────────────────────────────────────────────────
    context "状態 :empty (ログイン済み + iPhone UA + step_records なし)" do
      let(:user) { create(:user) }

      before do
        login_as(user)
        get root_path, headers: { "User-Agent" => iphone_ua }
      end

      it "200 OK を返す" do
        expect(response).to have_http_status(:ok)
      end

      include_examples "banner_empty が表示される"

      it "表示名が current_user.name である" do
        expect(response.body).to include(user.name)
      end

      it "Google でログインボタンをどこにも表示しない" do
        expect(response.body).not_to include("Google でログイン")
      end

      it "ログアウトボタンを表示する" do
        expect(response.body).to include("ログアウト")
      end

      it "/settings へのリンクを含む" do
        expect(response.body).to include("/settings")
      end
    end

    # ─────────────────────────────────────────────────
    # 既存テストの回帰防止 (データなし = :empty 状態, UA 未指定)
    # ─────────────────────────────────────────────────
    context "ログイン時 (データなし = :empty 状態)" do
      let(:user) { create(:user) }

      before do
        mock_google_oauth2(uid: user.uid, email: user.email, name: user.name)
        get auth_callback_path(provider: "google_oauth2")
        get root_path
      end

      it "200 OK を返す" do
        expect(response).to have_http_status(:ok)
      end

      it "ダッシュボードのトップバーにユーザー名を含む" do
        expect(response.body).to include(user.name)
      end

      it "empty バナーに設定リンクを表示する" do
        expect(response.body).to include("/settings")
      end

      it "Google でログインボタンをどこにも表示しない" do
        expect(response.body).not_to include("Google でログイン")
      end

      it "ヘッダにログアウトボタンを表示する" do
        expect(response.body).to include("ログアウト")
      end
    end
  end
end
