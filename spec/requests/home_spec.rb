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
    it "「Android アプリ版」「Health Connect」「dogfood」を含む" do
      # 子 6 (#125) で Capacitor アプリ版が dogfood 段階に到達したため、
      # 「現在開発中」→「Android アプリ版で Health Connect と連携できます」に文言更新済 (PR #140)
      expect(response.body).to include("Android アプリ版")
      expect(response.body).to include("Health Connect")
      expect(response.body).to include("dogfood")
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

      # Issue #70: 月初ゼロ励まし。今月のレコードがある = this_month が 0 ではないので励ましは出ない。
      it "今月の貯カロリーがある (this_month > 0) ので月初励ましは表示されない" do
        expect(response.body).not_to include("月の始まり。今日の一歩が貯まりはじめる")
      end
    end

    # ─────────────────────────────────────────────────
    # 状態 :iphone_with_data かつ「今月のレコードがゼロ + 累計あり」 (= 月初励まし発火条件、Issue #70)
    # ─────────────────────────────────────────────────
    context "状態 :iphone_with_data + 今月 0 + 累計あり (= 月初励まし発火条件、Issue #70)" do
      # travel_to で日付を固定して月境界 issue を予防 (= code-reviewer 指摘)。
      # CI が月末/月初に走った時の偶発バグを防ぎ、再現性を担保する。
      around { |ex| travel_to(Date.new(2026, 5, 15)) { ex.run } }

      let(:user) { create(:user) }
      # 先月の StepRecord のみ作成 → this_month = 0、total > 0
      let!(:last_month_record) do
        create(:step_record, user: user, recorded_on: Date.new(2026, 4, 15), steps: 5000)
      end

      before do
        login_as(user)
        get root_path, headers: { "User-Agent" => iphone_ua }
      end

      it "月初励ましメッセージを表示する" do
        expect(response.body).to include("月の始まり。今日の一歩が貯まりはじめる")
      end

      it "累計値 200 kcal (= 5000 * 0.04) が励まし内に表示される" do
        expect(response.body).to include("200")
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

  # ---------------------------------------------------------------------------
  # Capacitor アプリ (= Android WebView) の allow_browser bypass (Issue #40 子 6 由来、PR #140)
  # ---------------------------------------------------------------------------
  describe "Capacitor アプリの allow_browser bypass" do
    capacitor_ua = "Mozilla/5.0 (Linux; Android 14; Pixel 7) AppleWebKit/537.36 " \
                   "(KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36 wv WeightDialyCapacitor"

    context "WeightDialyCapacitor suffix を含む UA" do
      before { get root_path, headers: { "User-Agent" => capacitor_ua } }

      it "406 Not Acceptable ではなく 200 OK を返す (= modern check を bypass)" do
        expect(response).to have_http_status(:ok)
      end
    end

    context "通常の Web ブラウザ UA (= suffix なし)" do
      before { get root_path, headers: { "User-Agent" => "Mozilla/4.0 (compatible; MSIE 6.0)" } }

      it "406 Not Acceptable を返す (= bypass が Capacitor 限定で effective)" do
        expect(response).to have_http_status(:not_acceptable)
      end
    end

    # 二重防衛: Capacitor 側 overrideUserAgent が壊れた場合の保険として、
    # UA に "; wv)" (= Android System WebView の標準マーカー) を含む UA も bypass する
    context "Android WebView UA (= ; wv) を含む、Capacitor 設定が壊れた場合のフォールバック)" do
      android_webview_ua = "Mozilla/5.0 (Linux; Android 14; Pixel 7; wv) AppleWebKit/537.36 " \
                           "(KHTML, like Gecko) Version/4.0 Chrome/120.0.0.0 Mobile Safari/537.36"
      before { get root_path, headers: { "User-Agent" => android_webview_ua } }

      it "406 ではなく 200 OK を返す (= 二重防衛、SNS 内蔵ブラウザ等も同パターンで通る)" do
        expect(response).to have_http_status(:ok)
      end
    end
  end
end
