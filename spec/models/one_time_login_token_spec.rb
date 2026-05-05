require "rails_helper"

RSpec.describe OneTimeLoginToken, type: :model do
  describe ".issue!" do
    let(:user) { create(:user) }

    it "creates a token with TTL = 30s" do
      freeze_time do
        record = described_class.issue!(user: user)
        expect(record.expires_at).to eq(30.seconds.from_now)
      end
    end

    it "generates a unique random token (= replay 攻撃耐性の前提)" do
      record_a = described_class.issue!(user: user)
      record_b = described_class.issue!(user: user)
      expect(record_a.token).not_to eq(record_b.token)
      expect(record_a.token.length).to be >= 32
    end

    it "is unused on creation" do
      expect(described_class.issue!(user: user).used?).to be(false)
    end
  end

  describe ".consume!" do
    let(:user) { create(:user) }

    context "with a valid live token" do
      let!(:record) { described_class.issue!(user: user) }

      it "marks it used and returns the record" do
        result = described_class.consume!(token: record.token)
        expect(result).to eq(record)
        expect(record.reload.used?).to be(true)
      end
    end

    context "with an expired token" do
      let!(:record) { create(:one_time_login_token, :expired, user: user) }

      it "returns nil and does not consume" do
        expect(described_class.consume!(token: record.token)).to be_nil
        expect(record.reload.used?).to be(false)
      end
    end

    context "with an already-used token (= replay 防止)" do
      let!(:record) { create(:one_time_login_token, :used, user: user) }

      it "returns nil" do
        expect(described_class.consume!(token: record.token)).to be_nil
      end
    end

    context "with an unknown token" do
      it "returns nil" do
        expect(described_class.consume!(token: "nonexistent_xxx")).to be_nil
      end
    end

    context "with a blank token" do
      it "returns nil" do
        expect(described_class.consume!(token: "")).to be_nil
      end
    end
  end

  describe "#expired?" do
    it "is true when expires_at has passed" do
      record = build(:one_time_login_token, expires_at: 1.second.ago)
      expect(record.expired?).to be(true)
    end

    it "is false when expires_at is still in the future" do
      record = build(:one_time_login_token, expires_at: 30.seconds.from_now)
      expect(record.expired?).to be(false)
    end
  end
end
