require "rails_helper"

RSpec.describe CalorieAdviceService::Ai do
  # SDK の内部実装 (= Net::HTTP / 独自 Transport) と WebMock の組み合わせで
  # request body 構築段階で StringIO エラーが起きるため、
  # SDK のメソッド単位で stub する。これにより:
  # - SDK の messages.create() に渡すパラメータ (= プロンプト構築) を直接検証できる
  # - レスポンス側 (= response.content の構造) も自由に組み立ててテスト可能
  # - WebMock + SDK の Net::HTTP レイヤー詳細に依存しない (= SDK upgrade 耐性)
  before do
    # Anthropic SDK の偶発的な実 API 接続を防止 (= 局所的に WebMock を有効化、他 spec への副作用なし)
    WebMock.disable_net_connect!(allow_localhost: true)
    allow(Rails.application.credentials).to receive(:dig).with(:anthropic, :api_key).and_return("sk-ant-test-key")
    allow(Anthropic::Client).to receive(:new).and_return(client_double)
    allow(client_double).to receive(:messages).and_return(messages_resource)
  end

  after { WebMock.allow_net_connect! }

  let(:client_double)     { double("Anthropic::Client") }
  let(:messages_resource) { double("Anthropic::Resources::Messages") }

  # tool_use block の input を Hash で返すモックレスポンス。
  # SDK 1.36 検証で input は通常 Hash で返ることを確認済み (= ai.rb の case 文で対応)。
  let(:successful_response) do
    items_hash = {
      items: [
        { name: "おにぎり 1 個", kcal: 180, label: "OK" },
        { name: "チョコモナカ 半分", kcal: 120, label: "余裕" },
        { name: "プリン", kcal: 150, label: "OK" }
      ]
    }
    tool_use_block = double("ToolUseBlock", type: :tool_use, input: items_hash)
    double("Anthropic::Models::Message", content: [ tool_use_block ])
  end

  describe ".call (API 成功)" do
    before { allow(messages_resource).to receive(:create).and_return(successful_response) }

    it "tool_use ブロックから 3 件の Item を抽出する" do
      items = described_class.call(300)
      expect(items.size).to eq(3)
    end

    it "1 件目の name / kcal / label を正しくマップする" do
      items = described_class.call(300)
      expect(items.first.name).to eq("おにぎり 1 個")
      expect(items.first.kcal).to eq(180)
      expect(items.first.label).to eq("OK")
    end

    it "戻り値の各要素が CalorieAdviceService::Item インスタンスである" do
      items = described_class.call(300)
      expect(items).to all(be_a(CalorieAdviceService::Item))
    end
  end

  describe ".call (API 失敗 → 上位サービスがフォールバックさせるための raise)" do
    context "Anthropic SDK が StandardError を raise する" do
      before { allow(messages_resource).to receive(:create).and_raise(StandardError, "API timeout") }

      it "raise する (= 上位 CalorieAdviceService が rescue してフォールバック)" do
        expect { described_class.call(300) }.to raise_error(StandardError)
      end
    end

    context "tool_use ブロックがない応答 (= 安全フィルタ作動などで text のみ返るケース)" do
      let(:text_only_response) do
        text_block = double("TextBlock", type: :text)
        double("Message", content: [ text_block ])
      end
      before { allow(messages_resource).to receive(:create).and_return(text_only_response) }

      it "raise する (= フォールバック経路)" do
        expect { described_class.call(300) }.to raise_error(StandardError, /No tool_use block/)
      end
    end

    context "tool_use の input.items が配列でない応答 (= スキーマ違反)" do
      let(:invalid_response) do
        tool_use_block = double("ToolUseBlock", type: :tool_use, input: { items: "not an array" })
        double("Message", content: [ tool_use_block ])
      end
      before { allow(messages_resource).to receive(:create).and_return(invalid_response) }

      it "raise する (= フォールバック経路)" do
        expect { described_class.call(300) }.to raise_error(StandardError, /Invalid items/)
      end
    end
  end

  describe "Anthropic Client への呼び出し内容" do
    before { allow(messages_resource).to receive(:create).and_return(successful_response) }

    it "Claude Haiku 4.5 モデルを指定する" do
      described_class.call(300)
      expect(messages_resource).to have_received(:create).with(hash_including(model: "claude-haiku-4-5"))
    end

    it "tool_choice で suggest_foods 強制を指定する (= JSON 出力強制)" do
      described_class.call(300)
      expect(messages_resource).to have_received(:create).with(
        hash_including(tool_choice: { type: "tool", name: "suggest_foods" })
      )
    end

    it "system プロンプトを文字列で渡す (= prompt caching は token 不足のため未使用、SYSTEM_PROMPT 構造を維持)" do
      described_class.call(300)
      expect(messages_resource).to have_received(:create) do |params|
        expect(params[:system_]).to be_a(String)
        expect(params[:system_]).to include("weight_dialy")
      end
    end

    it "ユーザーメッセージに今日の消費カロリーを含める" do
      described_class.call(300)
      expect(messages_resource).to have_received(:create) do |params|
        expect(params[:messages].first[:content]).to include("300 kcal")
      end
    end

    it "max_retries: 0 で Client を初期化する (= フォールバック側で制御)" do
      described_class.call(300)
      expect(Anthropic::Client).to have_received(:new).with(hash_including(max_retries: 0))
    end

    it "timeout: 5 秒で Client を初期化する" do
      described_class.call(300)
      expect(Anthropic::Client).to have_received(:new).with(hash_including(timeout: 5))
    end
  end
end
