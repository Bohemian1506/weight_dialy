require "rails_helper"

RSpec.describe CalorieAdviceService do
  describe ".call" do
    subject(:result) { CalorieAdviceService.call(kcal) }

    shared_examples "正常なレスポンス構造" do
      it "headline キーを持つ" do
        expect(result.headline).to be_present
      end

      it "items を 3 件返す" do
        expect(result.items.size).to eq(3)
      end

      it "button_label キーを持つ" do
        expect(result.button_label).to be_present
      end

      it "各 item が name / kcal / label 構造を持つ" do
        result.items.each do |item|
          expect(item).to respond_to(:name, :kcal, :label)
          expect(item.name).to be_a(String)
          expect(item.kcal).to be_a(Integer)
          expect(item.label).to be_nil.or(be_a(String))
        end
      end
    end

    context "0 kcal (最小値)" do
      let(:kcal) { 0 }

      include_examples "正常なレスポンス構造"

      it "headline が「きょうのプラマイ提案」である" do
        expect(result.headline).to eq("きょうのプラマイ提案")
      end

      it "button_label が規定文字列である" do
        expect(result.button_label).to eq("食べたい物から逆算 →")
      end
    end

    context "kcal 帯の境界値" do
      # tiny 帯: 0...50
      context "49 kcal (tiny 帯上限)" do
        let(:kcal) { 49 }
        include_examples "正常なレスポンス構造"
      end

      # small 帯: 50...100
      context "50 kcal (small 帯下限)" do
        let(:kcal) { 50 }
        include_examples "正常なレスポンス構造"
      end

      context "99 kcal (small 帯上限)" do
        let(:kcal) { 99 }
        include_examples "正常なレスポンス構造"
      end

      # medium 帯: 100...200
      context "100 kcal (medium 帯下限)" do
        let(:kcal) { 100 }
        include_examples "正常なレスポンス構造"
      end

      context "199 kcal (medium 帯上限)" do
        let(:kcal) { 199 }
        include_examples "正常なレスポンス構造"
      end

      # large 帯: 200...400
      context "200 kcal (large 帯下限)" do
        let(:kcal) { 200 }
        include_examples "正常なレスポンス構造"
      end

      context "399 kcal (large 帯上限)" do
        let(:kcal) { 399 }
        include_examples "正常なレスポンス構造"
      end

      # xlarge 帯: 400 以上
      context "400 kcal (xlarge 帯下限)" do
        let(:kcal) { 400 }
        include_examples "正常なレスポンス構造"
      end
    end

    describe "label の付与ロジック" do
      # total_kcal = 200, item.kcal = 90 → ratio 0.45 → "余裕"
      context "ratio < 0.5 のとき" do
        let(:kcal) { 200 }

        it "「余裕」または「OK」またはnilのいずれかを返す" do
          labels = result.items.map(&:label)
          expect(labels).to all(satisfy { |l| [ "余裕", "OK", nil ].include?(l) })
        end
      end

      # total_kcal = 0 の場合は ratio = 0 → 全件 "余裕"
      context "total_kcal = 0 の場合" do
        let(:kcal) { 0 }

        it "全 item の label が「余裕」である" do
          expect(result.items.map(&:label)).to all(eq("余裕"))
        end
      end
    end
  end
end
