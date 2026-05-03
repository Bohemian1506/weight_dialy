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

      it "レスポンスボディに「Apple Shortcuts 連携」を含む" do
        expect(response.body).to include("Apple Shortcuts 連携")
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
        expect(response.body).to include("https://www.icloud.com/shortcuts/d2fb3cca3a3e47549577231a011dffee")
      end

      it "Step 3 のボタン文言が「ショートカットをインストール」である" do
        expect(response.body).to include("ショートカットをインストール")
      end

      it "iCloud リンクが target=\"_blank\" + rel=\"noopener noreferrer\" 付きで描画される" do
        # 属性順は Rails / link_to に依存し変動しうるため、a タグ抽出後に個別検査する
        link_tag = response.body[%r{<a\b[^>]*href="https://www\.icloud\.com/shortcuts/[^"]+"[^>]*>}]
        expect(link_tag).not_to be_nil, "iCloud Shortcut リンクの a タグが見つからない"
        expect(link_tag).to include('target="_blank"')
        expect(link_tag).to include('rel="noopener noreferrer"')
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
