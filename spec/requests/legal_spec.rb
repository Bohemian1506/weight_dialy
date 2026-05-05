require "rails_helper"

RSpec.describe "Legal", type: :request do
  def login(user)
    mock_google_oauth2(uid: user.uid, email: user.email, name: user.name)
    get auth_callback_path(provider: "google_oauth2")
  end

  # ---------------------------------------------------------------------------
  # GET /privacy
  # ---------------------------------------------------------------------------
  describe "GET /privacy" do
    context "未ログイン時" do
      before { get privacy_path }

      it "200 OK を返す" do
        expect(response).to have_http_status(:ok)
      end

      it "「プライバシーポリシー」を含む" do
        expect(response.body).to include("プライバシーポリシー")
      end

      it "お問い合わせメールアドレスを含む" do
        expect(response.body).to include("weightdaily3@gmail.com")
      end

      it "「Anthropic」を含む" do
        expect(response.body).to include("Anthropic")
      end

      it "「Render」を含む" do
        expect(response.body).to include("Render")
      end

      it "「Google」を含む" do
        expect(response.body).to include("Google")
      end
    end

    context "ログイン済み時" do
      let(:user) { create(:user) }

      before do
        login(user)
        get privacy_path
      end

      it "200 OK を返す" do
        expect(response).to have_http_status(:ok)
      end

      it "「プライバシーポリシー」を含む" do
        expect(response.body).to include("プライバシーポリシー")
      end
    end
  end

  # ---------------------------------------------------------------------------
  # GET /terms
  # ---------------------------------------------------------------------------
  describe "GET /terms" do
    context "未ログイン時" do
      before { get terms_path }

      it "200 OK を返す" do
        expect(response).to have_http_status(:ok)
      end

      it "「利用規約」を含む" do
        expect(response.body).to include("利用規約")
      end

      it "「禁止事項」を含む" do
        expect(response.body).to include("禁止事項")
      end

      it "免責事項の文言を含む" do
        expect(response.body).to include("医療的助言、診断、治療を提供するものではありません")
      end

      it "お問い合わせメールアドレスを含む" do
        expect(response.body).to include("weightdaily3@gmail.com")
      end
    end

    context "ログイン済み時" do
      let(:user) { create(:user) }

      before do
        login(user)
        get terms_path
      end

      it "200 OK を返す" do
        expect(response).to have_http_status(:ok)
      end

      it "「利用規約」を含む" do
        expect(response.body).to include("利用規約")
      end
    end
  end
end
