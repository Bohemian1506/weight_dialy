require "rails_helper"

RSpec.describe CalorieAdviceService do
  # メイン service の挙動 (= AI 成功時 / フォールバック時) のみここでテストする。
  # CalorieAdviceService::Ai (Anthropic API 呼び出し) は spec/services/calorie_advice_service/ai_spec.rb
  # CalorieAdviceService::Static (固定リスト) はメイン経由で網羅する (= 旧 CalorieAdviceService spec を継承)
  describe ".call" do
    subject(:result) { CalorieAdviceService.call(kcal) }

    # 既存テストは AI 失敗時のフォールバック (= Static) 経路を検証する。
    # これにより旧 CalorieAdviceService の挙動 (kcal 帯別選択 + ratio ラベル付与) を
    # Static service の中で継続的に検証できる。
    before do
      allow(CalorieAdviceService::Ai).to receive(:call).and_raise(StandardError, "AI disabled in test")
      allow(Rails.logger).to receive(:warn) # フォールバックの warn ログをサイレント化
    end

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

    # Issue #163 (= 0 kcal バナナ余裕誤誘導) で導入された空ステート。
    # しきい値未満 (= 30 kcal 未満) では AI / Static を呼ばず ZERO_HEADLINE + ZERO_BODY を返す。
    context "0 kcal (= ZERO_THRESHOLD 未満、空ステート)" do
      let(:kcal) { 0 }

      it "items が空配列" do
        expect(result.items).to eq([])
      end

      it "headline が ZERO_HEADLINE「今日のスタートはここから」" do
        expect(result.headline).to eq("今日のスタートはここから")
      end

      it "body に ZERO_BODY 文言が入る (= 食品提案の代わり)" do
        expect(result.body).to eq("歩数が記録されると、食べていいものを提案するよ。")
      end

      it "button_label が nil (= 0 kcal 時はボタン非表示、design レビュー指摘)" do
        expect(result.button_label).to be_nil
      end

      it "ai_used が false (= AI を呼ばずに即返す)" do
        expect(result.ai_used).to be false
      end

      it "AI を呼ばない (= API コスト節約、ガード節で先にリターン)" do
        expect(CalorieAdviceService::Ai).not_to receive(:call)
        result
      end
    end

    context "29 kcal (= ZERO_THRESHOLD 境界の直前、空ステート扱い)" do
      let(:kcal) { 29 }

      it "items が空配列 (= しきい値未満は 0 と同じ扱い)" do
        expect(result.items).to eq([])
      end

      it "headline が ZERO_HEADLINE" do
        expect(result.headline).to eq("今日のスタートはここから")
      end
    end

    context "30 kcal (= ZERO_THRESHOLD ぴったり、通常ステート)" do
      let(:kcal) { 30 }

      include_examples "正常なレスポンス構造"

      it "headline が通常 HEADLINE (= 空ステートではない)" do
        expect(result.headline).to eq("今日の消費カロリーならこれ食べられるよ〜")
      end

      it "items が 3 件" do
        expect(result.items.size).to eq(3)
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

      # Issue #163 fix 後: total_kcal = 0 (= しきい値未満) は空ステートを返すため、
      # items が空配列で「余裕」誤誘導が発生しないことを保証する (= 旧バグの回帰防止)。
      context "total_kcal = 0 (= 旧版バグの回帰防止)" do
        let(:kcal) { 0 }

        it "items が空配列 (= 全件「余裕」誤誘導の元凶を断つ)" do
          expect(result.items).to eq([])
        end
      end
    end
  end

  describe "AI 成功時とフォールバック時の分岐" do
    let(:kcal) { 200 }

    # ai_available? を true にするため credentials を stub (= 上のメインテストとは別に、AI 経路を試したいので)
    before do
      allow(Rails.application.credentials).to receive(:dig).with(:anthropic, :api_key).and_return("sk-ant-test")
    end

    context "Ai.call が成功する時" do
      let(:ai_items) do
        [
          CalorieAdviceService::Item.new(name: "AI 提案 A", kcal: 80, label: "余裕"),
          CalorieAdviceService::Item.new(name: "AI 提案 B", kcal: 150, label: "OK"),
          CalorieAdviceService::Item.new(name: "AI 提案 C", kcal: 220, label: nil)
        ]
      end

      # CalorieAdviceService::Ai.call 全体を stub しているため Ai 内部の Anthropic::Client.new も
      # 呼ばれない (= 実 API 接続なし)。SDK の Client メソッド単位の検証は ai_spec.rb 側で別途実施する。
      before do
        allow(CalorieAdviceService::Ai).to receive(:call).and_return(ai_items)
        allow(Rails.logger).to receive(:info)
      end

      it "Result.ai_used が true (= Powered by Claude バッジ表示用、Issue #75)" do
        expect(CalorieAdviceService.call(kcal).ai_used).to be true
      end

      it "AI が返した items をそのまま Result.items に詰める" do
        expect(CalorieAdviceService.call(kcal).items.map(&:name)).to eq([ "AI 提案 A", "AI 提案 B", "AI 提案 C" ])
      end

      it "headline は固定の新コピーを返す (= AI 出力ではない)" do
        expect(CalorieAdviceService.call(kcal).headline).to eq("今日の消費カロリーならこれ食べられるよ〜")
      end
    end

    context "Ai.call が StandardError を raise する時 (= フォールバック発火)" do
      before do
        allow(CalorieAdviceService::Ai).to receive(:call).and_raise(StandardError, "API timeout")
        allow(Rails.logger).to receive(:warn)
      end

      it "Static.call の結果を返す (= Result.items が 3 件)" do
        expect(CalorieAdviceService.call(kcal).items.size).to eq(3)
      end

      it "Rails.logger.warn にフォールバックログを出力する" do
        CalorieAdviceService.call(kcal)
        expect(Rails.logger).to have_received(:warn).with(/AI failed.*falling back to static/)
      end

      it "Result.ai_used が false (= Powered by Claude バッジ非表示、Issue #75)" do
        expect(CalorieAdviceService.call(kcal).ai_used).to be false
      end
    end

    context "credentials に api_key が無い時 (= test/development デフォルト)" do
      before do
        allow(Rails.application.credentials).to receive(:dig).with(:anthropic, :api_key).and_return(nil)
        # AI が呼ばれてはいけない (= ai_available? が false の時点で skip)
      end

      it "Ai.call を呼ばずに Static のみで完結する" do
        expect(CalorieAdviceService::Ai).not_to receive(:call)
        result = CalorieAdviceService.call(kcal)
        expect(result.items.size).to eq(3)
      end

      it "Result.ai_used が false" do
        expect(CalorieAdviceService.call(kcal).ai_used).to be false
      end
    end
  end
end
