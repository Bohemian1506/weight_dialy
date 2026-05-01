require "rails_helper"

RSpec.describe WebhookDelivery, type: :model do
  describe "associations" do
    it "belongs to user optionally" do
      association = described_class.reflect_on_association(:user)
      expect(association).not_to be_nil
      expect(association.macro).to eq(:belongs_to)
      expect(association.options[:optional]).to be(true)
    end

    it "can be created without a user (authentication failure case)" do
      delivery = build(:webhook_delivery, user: nil)
      expect(delivery).to be_valid
    end

    it "can be created with a user" do
      delivery = build(:webhook_delivery, user: create(:user))
      expect(delivery).to be_valid
    end
  end

  describe "validations" do
    describe "status inclusion" do
      %w[success unauthorized invalid].each do |valid_status|
        it "is valid with status '#{valid_status}'" do
          delivery = build(:webhook_delivery, status: valid_status)
          expect(delivery).to be_valid
        end
      end

      it "is invalid with an unrecognized status" do
        delivery = build(:webhook_delivery, status: "foo")
        expect(delivery).not_to be_valid
      end

      it "is invalid with a blank status" do
        delivery = build(:webhook_delivery, status: "")
        expect(delivery).not_to be_valid
      end
    end
  end
end
