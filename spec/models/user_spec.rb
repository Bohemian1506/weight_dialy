require 'rails_helper'

RSpec.describe User, type: :model do
  describe "validations" do
    it "is valid with all required attributes" do
      user = build(:user)
      expect(user).to be_valid
    end

    it "is invalid without provider" do
      user = build(:user, provider: nil)
      expect(user).not_to be_valid
    end

    it "is invalid without uid" do
      user = build(:user, uid: nil)
      expect(user).not_to be_valid
    end

    it "is invalid without email" do
      user = build(:user, email: nil)
      expect(user).not_to be_valid
    end

    it "is invalid without name" do
      user = build(:user, name: nil)
      expect(user).not_to be_valid
    end

    it "rejects duplicate uid within the same provider" do
      create(:user, provider: "google_oauth2", uid: "same_uid")
      duplicate = build(:user, provider: "google_oauth2", uid: "same_uid")
      expect(duplicate).not_to be_valid
    end

    it "allows the same uid when provider differs" do
      create(:user, provider: "google_oauth2", uid: "same_uid")
      other_provider = build(:user, provider: "github", uid: "same_uid")
      expect(other_provider).to be_valid
    end
  end

  describe "has_secure_token :webhook_token" do
    it "auto-generates webhook_token on create" do
      user = create(:user)
      expect(user.webhook_token).not_to be_nil
    end

    it "generates a token of at least 24 characters" do
      user = create(:user)
      expect(user.webhook_token.length).to be >= 24
    end

    it "generates unique tokens for different users" do
      user1 = create(:user)
      user2 = create(:user)
      expect(user1.webhook_token).not_to eq(user2.webhook_token)
    end

    it "allows regenerating the token via regenerate_webhook_token" do
      user = create(:user)
      original_token = user.webhook_token
      user.regenerate_webhook_token
      expect(user.reload.webhook_token).not_to eq(original_token)
    end
  end

  describe ".from_omniauth" do
    let(:auth) do
      OmniAuth::AuthHash.new(
        provider: "google_oauth2",
        uid: "google_123",
        info: OmniAuth::AuthHash::InfoHash.new(
          email: "new@example.com",
          name: "New User",
          image: "https://example.com/avatar.jpg"
        )
      )
    end

    context "when the user does not exist yet" do
      it "creates a new user record" do
        expect { User.from_omniauth(auth) }.to change(User, :count).by(1)
      end

      it "saves image_url from auth.info.image" do
        user = User.from_omniauth(auth)
        expect(user.image_url).to eq("https://example.com/avatar.jpg")
      end
    end

    context "when the user already exists (same provider + uid)" do
      before { create(:user, provider: "google_oauth2", uid: "google_123", email: "old@example.com", name: "Old Name") }

      it "does not create a new record" do
        expect { User.from_omniauth(auth) }.not_to change(User, :count)
      end

      it "updates email" do
        user = User.from_omniauth(auth)
        expect(user.email).to eq("new@example.com")
      end

      it "updates name" do
        user = User.from_omniauth(auth)
        expect(user.name).to eq("New User")
      end

      it "updates image_url" do
        user = User.from_omniauth(auth)
        expect(user.image_url).to eq("https://example.com/avatar.jpg")
      end
    end
  end
end
