require "rails_helper"

RSpec.describe CleanupOneTimeLoginTokensJob, type: :job do
  subject(:job) { described_class.new }

  # GC 閾値: expires_at < 1.day.ago のレコードを削除する。
  # 未使用 / 使用済みは問わない (= 期限が 1 日以上前なら保持不要)。

  describe "#perform" do
    let(:user) { create(:user) }

    context "when expires_at is older than 1 day ago (= GC 対象)" do
      let!(:stale_unused) do
        # expires_at を 1.day.ago より古く設定: 未使用トークン
        create(:one_time_login_token, user: user, expires_at: 1.day.ago - 1.second)
      end

      let!(:stale_used) do
        # expires_at を 1.day.ago より古く設定: 使用済みトークン
        create(:one_time_login_token, :used, user: user, expires_at: 1.day.ago - 1.second)
      end

      it "deletes stale unused tokens" do
        job.perform
        expect(OneTimeLoginToken.exists?(stale_unused.id)).to be(false)
      end

      it "deletes stale used tokens" do
        job.perform
        expect(OneTimeLoginToken.exists?(stale_used.id)).to be(false)
      end

      it "reduces the total count by the number of stale records" do
        expect { job.perform }.to change(OneTimeLoginToken, :count).by(-2)
      end
    end

    context "when expires_at is exactly at the boundary (= 1.day.ago より新しい側)" do
      let!(:boundary_token) do
        # expires_at が 1.day.ago + 1.second = 閾値より新しいため残る
        create(:one_time_login_token, user: user, expires_at: 1.day.ago + 1.second)
      end

      it "does not delete the token just inside the boundary" do
        job.perform
        expect(OneTimeLoginToken.exists?(boundary_token.id)).to be(true)
      end
    end

    context "when expires_at is in the future (= まだ有効なトークン)" do
      let!(:live_token) { create(:one_time_login_token, user: user) }

      it "does not delete the live token" do
        job.perform
        expect(OneTimeLoginToken.exists?(live_token.id)).to be(true)
      end

      it "does not change the total count" do
        expect { job.perform }.not_to change(OneTimeLoginToken, :count)
      end
    end

    context "when stale and live tokens coexist" do
      let!(:stale_token) do
        create(:one_time_login_token, user: user, expires_at: 1.day.ago - 1.second)
      end

      let!(:live_token) { create(:one_time_login_token, user: user) }

      it "deletes only the stale token and keeps the live one" do
        job.perform
        expect(OneTimeLoginToken.exists?(stale_token.id)).to be(false)
        expect(OneTimeLoginToken.exists?(live_token.id)).to be(true)
      end
    end
  end
end
