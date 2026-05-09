require "rails_helper"

RSpec.describe "Settings", type: :request do
  # ---------------------------------------------------------------------------
  # ログインヘルパー
  #
  # sessions_spec.rb / home_spec.rb と同じパターン:
  # mock_google_oauth2 で OmniAuth モックをセットしてから
  # GET /auth/google_oauth2/callback を叩き、実際のログインフローを通す。
  # これにより session[:user_id] が張られた状態になる。
  # ---------------------------------------------------------------------------
  def login(user)
    mock_google_oauth2(uid: user.uid, email: user.email, name: user.name)
    get auth_callback_path(provider: "google_oauth2")
  end

  # ---------------------------------------------------------------------------
  # GET /settings
  # ---------------------------------------------------------------------------
  describe "GET /settings" do
    context "未ログイン時" do
      before { get settings_path }

      it "302 リダイレクトを返す" do
        expect(response).to have_http_status(:found)
      end

      it "root_path へリダイレクトする" do
        expect(response).to redirect_to(root_path)
      end

      it "flash[:alert] にログイン要求メッセージをセットする" do
        expect(flash[:alert]).to eq("ログインが必要です")
      end
    end

    context "ログイン時" do
      let(:user) { create(:user) }

      before do
        login(user)
        get settings_path
      end

      it "200 OK を返す" do
        expect(response).to have_http_status(:ok)
      end

      it "レスポンスボディに current_user の webhook_token を含む" do
        expect(response.body).to include(user.webhook_token)
      end

      it "レスポンスボディに webhook URL を含む" do
        expect(response.body).to include(webhooks_health_data_url)
      end

      it "レスポンスボディに「データ連携の設定」見出しを含む (= Android user に「関係ない設定」感を出さないため中立タイトル化、公開前 polish)" do
        expect(response.body).to include("データ連携の設定")
      end

      it "レスポンスボディにリード文の「Apple Shortcuts」を含む (= 既存対応端末の明示)" do
        expect(response.body).to include("Apple Shortcuts")
      end

      it "レスポンスボディに「Step 1」を含む" do
        expect(response.body).to include("Step 1")
      end

      it "レスポンスボディに「Step 2」を含む" do
        expect(response.body).to include("Step 2")
      end

      it "レスポンスボディに「Step 3」を含む" do
        expect(response.body).to include("Step 3")
      end

      it "Step 3 に iCloud Shortcut の配布リンクを含む" do
        expect(response.body).to include("https://www.icloud.com/shortcuts/7e0199f480824ae1959a0833a443f564")
      end

      it "Step 3 のボタン文言が「ショートカットをインストール」である" do
        expect(response.body).to include("ショートカットをインストール")
      end

      it "Step 3 に HealthKit 権限許可の案内文言を含む (= 配布版の必須案内、借りた iPhone 検証で発覚)" do
        # <strong> 等の HTML 強調タグに依存しないよう、キーワード「ヘルスケアへのアクセス」と「許可」を別々に検査
        expect(response.body).to include("ヘルスケアへのアクセス")
        expect(response.body).to include("を許可")
      end

      it "iCloud リンクが target=\"_blank\" + rel=\"noopener noreferrer\" 付きで描画される" do
        # 属性順は Rails / link_to に依存し変動しうるため、a タグ抽出後に個別検査する
        link_tag = response.body[%r{<a\b[^>]*href="https://www\.icloud\.com/shortcuts/[^"]+"[^>]*>}]
        expect(link_tag).not_to be_nil, "iCloud Shortcut リンクの a タグが見つからない"
        expect(link_tag).to include('target="_blank"')
        expect(link_tag).to include('rel="noopener noreferrer"')
      end
    end

    # -------------------------------------------------------------------------
    # Health Connect 連携セクション (Issue #40 子 3 / #121)
    # Capacitor (Android アプリ) でのみ動的表示、Web 版では display: none 維持
    # -------------------------------------------------------------------------
    context "ログイン時 (Health Connect セクション)" do
      let(:user) { create(:user) }

      before do
        login(user)
        get settings_path
      end

      it "Android Health Connect 連携セクションを含む (= Stimulus controller 経由でレンダリング)" do
        # PR #270 で見出しから絵文字 📱 を削除したが、`include` は部分文字列マッチのため、
        # 絵文字あり/なし両対応で本アサーションはそのまま通過する。
        expect(response.body).to include("Android Health Connect 連携")
        expect(response.body).to include('data-controller="native-health"')
        # Issue #138: 401 失敗時の Settings 誘導ボタンが Stimulus target として登録されている。
        expect(response.body).to include('data-native-health-target="recoveryButton"')
        # Issue #273: 2 mode 化された recoveryAction action と data-mode="settings" 初期値。
        expect(response.body).to include('data-action="click->native-health#recoveryAction"')
        expect(response.body).to include('data-mode="settings"')
      end

      it "Web 版では display: none で初期表示する (= Capacitor 検知時のみ表示に切り替わる)" do
        # native-health controller を持つ要素の inline style に display: none が含まれる
        expect(response.body).to match(/data-controller="native-health"[^>]*style="[^"]*display: none/)
      end

      # 子 5a (#123): 同期ボタン + Webhook POST フロー
      it "同期ボタン (= click->native-health#sync action) を含む" do
        expect(response.body).to include('data-action="click->native-health#sync"')
      end

      it "webhook_token を Stimulus values 経由で埋め込む (= Capacitor 検知時のみ JS 参照)" do
        expect(response.body).to include('data-native-health-webhook-token-value="')
        expect(response.body).to include(user.webhook_token)
      end
    end

    # -------------------------------------------------------------------------
    # 受信履歴セクション (Issue #53)
    # -------------------------------------------------------------------------
    context "ログイン時 (受信履歴セクション)" do
      let(:user) { create(:user) }

      before { login(user) }

      context "WebhookDelivery が 0 件のとき" do
        before { get settings_path }

        it "「送信ログ」見出しを表示する" do
          expect(response.body).to include("送信ログ")
        end

        it "プレースホルダー「まだ Shortcut からの送信はありません」を表示する" do
          expect(response.body).to include("まだ Shortcut からの送信はありません")
        end

        # Issue #48 指摘 0: 受信ログ無しなら従来通り Step 3 をフルサイズ表示
        it "Step 3 のフル案内 (= 「あとはショートカットを入れるだけ」) を表示する" do
          expect(response.body).to include("あとはショートカットを入れるだけ")
        end

        it "Step 3 非表示時の再追加リンク (= 「別の端末に追加したい」) は表示しない" do
          expect(response.body).not_to include("別の端末に追加したい")
        end
      end

      context "success の WebhookDelivery が 1 件あるとき" do
        let!(:delivery) do
          create(:webhook_delivery, user: user, status: "success",
                                    payload: { "records" => [ { "recorded_on" => "2026-05-03", "steps" => 8000 } ] },
                                    received_at: 5.minutes.ago)
        end

        before { get settings_path }

        it "ステータスラベル「成功」を表示する" do
          expect(response.body).to include("成功")
        end

        it "件数 (1 件) を表示する" do
          expect(response.body).to include("1 件")
        end

        it "sketch-status-success クラスを描画する" do
          expect(response.body).to include("sketch-status-success")
        end

        it "プレースホルダーを表示しない" do
          expect(response.body).not_to include("まだ Shortcut からの送信はありません")
        end

        # Issue #58: 受信ログがある時はセクション冒頭に「最終送信」表示
        it "「最終送信:」の文言を表示する" do
          expect(response.body).to include("最終送信:")
        end

        # Issue #48 指摘 0: 受信ログがある = Step 3 のフル案内を非表示にする
        it "Step 3 のフル案内 (= 「あとはショートカットを入れるだけ」) を表示しない" do
          expect(response.body).not_to include("あとはショートカットを入れるだけ")
        end

        # Issue #48 指摘 0: 代わりに再追加導線リンクを控えめに表示
        it "「別の端末に追加したい場合はこちら」の再追加リンクを表示する" do
          expect(response.body).to include("別の端末に追加したい")
        end
      end

      context "invalid の WebhookDelivery が 1 件あるとき" do
        let!(:delivery) do
          create(:webhook_delivery, user: user, status: "invalid",
                                    payload: { "records" => [ { "recorded_on" => "bad" } ] },
                                    error_message: "recorded_on must be yyyy-MM-dd format: got \"bad\"",
                                    received_at: 1.hour.ago)
        end

        before { get settings_path }

        it "ステータスラベル「エラー」を表示する" do
          expect(response.body).to include("エラー")
        end

        it "sketch-status-invalid クラスを描画する" do
          expect(response.body).to include("sketch-status-invalid")
        end

        it "件数表示は省略する (= invalid 時の '1 件' は誤読を生むため非表示)" do
          expect(response.body).not_to include("sketch-webhook-history-count")
        end

        it "error_message を全文表示する (truncate なし、モバイル hover 不可問題対応)" do
          expect(response.body).to include("recorded_on must be yyyy-MM-dd format: got")
        end
      end

      context "unauthorized の WebhookDelivery (user_id = nil) があるとき" do
        let!(:unauthorized_delivery) do
          create(:webhook_delivery, user: nil, status: "unauthorized",
                                    payload: { "records" => [] },
                                    received_at: 10.minutes.ago)
        end

        before { get settings_path }

        it "unauthorized 行は表示しない (MVP デフォルト、#55 で設定化予定)" do
          expect(response.body).not_to include("認証失敗")
        end

        it "0 件扱いでプレースホルダーを表示する" do
          expect(response.body).to include("まだ Shortcut からの送信はありません")
        end
      end

      context "WebhookDelivery が 6 件以上あるとき" do
        before do
          7.times do |i|
            create(:webhook_delivery, user: user, status: "success",
                                      payload: { "records" => [ { "recorded_on" => "2026-05-#{i + 1}" } ] },
                                      received_at: i.hours.ago)
          end
          get settings_path
        end

        it "直近 5 件のみ描画する (= sketch-status-success の出現回数が 5)" do
          expect(response.body.scan(/sketch-status-success/).size).to eq(5)
        end
      end

      context "payload の records が配列でないとき (= 不正 payload)" do
        let!(:delivery) do
          create(:webhook_delivery, user: user, status: "invalid",
                                    payload: { "raw" => "not json" },
                                    error_message: "JSON parse error",
                                    received_at: 5.minutes.ago)
        end

        before { get settings_path }

        it "件数表示用の sketch-webhook-history-count クラスは描画されない" do
          # タイトル「受信履歴 (直近 5 件)」とぶつからないよう、件数バッジの class 出現数で判定
          expect(response.body).not_to include("sketch-webhook-history-count")
        end
      end
    end

    # -------------------------------------------------------------------------
    # Web Android user 向けプロモセクション出し分け (Issue #184)
    # -------------------------------------------------------------------------
    context "UA 別 Android アプリ案内セクション出し分け" do
      let(:user) { create(:user) }

      before { login(user) }

      context "Web 版 Android Chrome UA でアクセスしたとき" do
        before do
          get settings_path, headers: {
            "HTTP_USER_AGENT" => "Mozilla/5.0 (Linux; Android 13; SM-S908U) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36"
          }
        end

        it "「インストール手順を準備中」セクションを表示する (= Web Android user 向け新セクション、Issue #184)" do
          # 新セクションのタイトル (= 「Android Health Connect 連携」) は既存の Capacitor 検知時セクションと
          # 同一文字列のため、新セクション固有の本文「インストール手順を準備中」で識別する。
          expect(response.body).to include("インストール手順を準備中")
        end
      end

      context "Android Capacitor アプリ (WeightDialyCapacitor を含む UA) でアクセスしたとき" do
        before do
          get settings_path, headers: {
            "HTTP_USER_AGENT" => "Mozilla/5.0 (Linux; Android 13; SM-S908U) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36 WeightDialyCapacitor"
          }
        end

        it "「インストール手順を準備中」セクションを表示しない (= 既存 native-health セクションが JS で代替表示)" do
          expect(response.body).not_to include("インストール手順を準備中")
        end
      end

      context "PC ブラウザ (Desktop UA) でアクセスしたとき" do
        before do
          get settings_path, headers: {
            "HTTP_USER_AGENT" => "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 Chrome/120.0.0.0 Safari/537.36"
          }
        end

        it "「インストール手順を準備中」セクションを表示しない (= Android UA でないため非表示)" do
          expect(response.body).not_to include("インストール手順を準備中")
        end
      end
    end
  end

  # ---------------------------------------------------------------------------
  # POST /settings/webhook_token (トークン再生成)
  # ---------------------------------------------------------------------------
  describe "POST /settings/webhook_token" do
    context "未ログイン時" do
      let(:user) { create(:user) }
      let(:original_token) { user.webhook_token }

      before do
        original_token # let を評価して DB に確定させる
        post regenerate_webhook_token_path
      end

      it "302 リダイレクトを返す" do
        expect(response).to have_http_status(:found)
      end

      it "root_path へリダイレクトする" do
        expect(response).to redirect_to(root_path)
      end

      it "webhook_token が変更されない" do
        expect(user.reload.webhook_token).to eq(original_token)
      end
    end

    context "ログイン時" do
      let(:user) { create(:user) }
      let(:original_token) { user.webhook_token }

      before do
        original_token # let を評価して DB に確定させる
        login(user)
        post regenerate_webhook_token_path
      end

      it "302 リダイレクトを返す" do
        expect(response).to have_http_status(:found)
      end

      it "settings_path へリダイレクトする" do
        expect(response).to redirect_to(settings_path)
      end

      it "flash[:notice] に再生成完了メッセージをセットする" do
        expect(flash[:notice]).to include("再生成")
      end

      it "webhook_token が元の値と異なる値に変更される" do
        expect(user.reload.webhook_token).not_to eq(original_token)
      end

      context "既存の StepRecord が保持される" do
        let!(:step_record) { create(:step_record, user: user, recorded_on: "2026-05-01", steps: 8000) }

        it "トークン再生成後も StepRecord が残っている" do
          expect(StepRecord.where(user: user)).to exist
        end

        it "トークン再生成後も StepRecord の steps 値が変わらない" do
          expect(StepRecord.find_by(user: user, recorded_on: "2026-05-01").steps).to eq(8000)
        end
      end
    end
  end
end
