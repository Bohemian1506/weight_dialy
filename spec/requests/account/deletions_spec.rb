require "rails_helper"

RSpec.describe "Account::Deletions", type: :request do
  # ---------------------------------------------------------------------------
  # ログインヘルパー (settings_spec.rb と同じパターン)
  # ---------------------------------------------------------------------------
  def login(user)
    mock_google_oauth2(uid: user.uid, email: user.email, name: user.name)
    get auth_callback_path(provider: "google_oauth2")
  end

  # ---------------------------------------------------------------------------
  # DELETE /account (退会)
  # ---------------------------------------------------------------------------
  describe "DELETE /account" do
    context "未ログイン時" do
      before { delete account_deletion_path }

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

    context "ログイン済み + 正常系" do
      let(:user) { create(:user) }

      before do
        login(user)
        delete account_deletion_path
      end

      it "302 リダイレクトを返す" do
        expect(response).to have_http_status(:found)
      end

      it "root_path へリダイレクトする" do
        expect(response).to redirect_to(root_path)
      end

      it "flash[:notice] に退会完了メッセージをセットする" do
        expect(flash[:notice]).to eq("退会完了しました。ご利用ありがとうございました。")
      end

      it "User レコードが削除される" do
        expect(User.find_by(id: user.id)).to be_nil
      end
    end

    context "ログイン済み + StepRecord が存在する場合" do
      let(:user) { create(:user) }
      let!(:step_records) { create_list(:step_record, 3, user: user) }

      before do
        login(user)
        delete account_deletion_path
      end

      it "User 削除時に StepRecord も cascade delete される" do
        expect(StepRecord.where(user_id: user.id)).to be_empty
      end
    end

    context "ログイン済み + WebhookDelivery が存在する場合" do
      let(:user) { create(:user) }
      let!(:deliveries) { create_list(:webhook_delivery, 2, user: user) }

      before do
        login(user)
        delete account_deletion_path
      end

      it "User 削除時に WebhookDelivery も cascade delete される" do
        expect(WebhookDelivery.where(user_id: user.id)).to be_empty
      end
    end

    context "ログイン済み + StepRecord / WebhookDelivery 両方存在する場合" do
      let(:user) { create(:user) }
      let!(:step_record) { create(:step_record, user: user) }
      let!(:delivery) { create(:webhook_delivery, user: user) }

      before do
        login(user)
        delete account_deletion_path
      end

      it "User レコードが削除される" do
        expect(User.find_by(id: user.id)).to be_nil
      end

      it "StepRecord が cascade delete される" do
        expect(StepRecord.where(user_id: user.id)).to be_empty
      end

      it "WebhookDelivery が cascade delete される" do
        expect(WebhookDelivery.where(user_id: user.id)).to be_empty
      end
    end

    context "セッションがリセットされる" do
      let(:user) { create(:user) }

      it "退会後は再度 /settings にアクセスしても root にリダイレクトされる" do
        login(user)
        delete account_deletion_path
        get settings_path
        expect(response).to redirect_to(root_path)
      end
    end
  end
end
