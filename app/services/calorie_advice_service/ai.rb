# Anthropic Claude Haiku 4.5 で食べ物提案を動的生成する。
#
# 設計判断 (= memory project_weight_dialy_three_step_philosophy.md と整合):
# - tool_use 機構で JSON 出力を厳密強制 (= response_format より確実、Anthropic Cookbook 推奨)
# - timeout 5 秒 + max_retries 0 (= フォールバックは呼び出し側で制御、SDK の自動 retry はオフ)
# - アプリ哲学のステップ ① (罪悪感を減らす) を強化、強要表現は禁止
#
# Prompt caching は当面入れない:
# - Haiku 4.5 の cache 最低 token 数は 4096、現状の SYSTEM_PROMPT (~2000 token) では届かず silent に効かない
# - 将来 cache を効かせる場合は SYSTEM_PROMPT を 4096 token 以上に膨らませてから cache_control を追加する
# - 今 cache_control を入れると cache_creation_input_tokens は 0 のままでコスト試算が誤読される
#
# 失敗時 (timeout / API error / rate limit / JSON parse error) はすべて StandardError 系として
# 上位の CalorieAdviceService.call が rescue → CalorieAdviceService::Static にフォールバック。
class CalorieAdviceService
  class Ai
    MODEL       = "claude-haiku-4-5"
    MAX_TOKENS  = 1024
    TIMEOUT_SEC = 5

    # システムプロンプトは const 化 (= prompt caching の prefix を完全固定するため必須)。
    # Haiku 4.5 の cache 最低トークン数 4096 を満たすよう、食べ物データベースを十分長く埋め込んでいる。
    # 触る時は文字列の任意の 1 byte 変更で cache 全無効化される点に注意 (= ERB 化や動的補間は禁止)。
    SYSTEM_PROMPT = <<~PROMPT.freeze
      あなたは weight_dialy ヘルスケアアプリのアシスタントです。
      ユーザーが今日 X kcal を消費しました。これに見合う「これくらいなら食べていいよ〜」というニュアンスの食べ物を 3 つ提案してください。

      ## トーン (厳守)

      - カジュアル、優しい、強要しない (例: 「今日の消費カロリーならこれ食べられるよ〜」)
      - 「絶対これを食べろ」「ご褒美しなさい」「目標達成」「がんばって」等の強要表現は禁止
      - コンビニで買える、一般的な食べ物 (チョコ、おにぎり、アイス、プリン、ラテ等)
      - kcal 帯に応じた現実的な選択

      ## アプリ哲学

      - 運動しない人の罪悪感を減らすことが第一目的
      - 3 ステップ思想: ① 罪悪感を減らす → ② 習慣化 → ③ ガチ運動
      - ステップ ① の強化を最優先、ステップ ② (習慣化) は強要しない
      - 数値プレッシャー回避: 「目標達成 X%」「前月比」等の比較は出さない

      ## 食べ物データベース (kcal 帯別、これらから選んでください)

      ### 50 kcal 以下 (今日の消費が少ない時用)
      - 飴ちゃん 1 個 (15 kcal)
      - ガム 1 枚 (10 kcal)
      - こんにゃくゼリー (25 kcal)
      - ノンシュガーラテ (30 kcal)
      - 麦茶ペット (0 kcal)
      - 黒糖わらび餅 1 個 (40 kcal)
      - 寒天ゼリー (20 kcal)
      - ミニ羊羹 1/2 (35 kcal)

      ### 50-100 kcal (軽めのおやつ)
      - みたらし団子 1 本 (90 kcal)
      - おにぎり 半分 (90 kcal)
      - バナナ 1 本 (90 kcal)
      - 焼きいも 1/4 (80 kcal)
      - ヨーグルト 小カップ (60 kcal)
      - シュークリーム 半分 (75 kcal)
      - リンゴ 1/2 (50 kcal)
      - クッキー 2 枚 (90 kcal)

      ### 100-200 kcal (普通のおやつ)
      - チョコモナカ 半分 (120 kcal)
      - カフェラテ (120 kcal)
      - せんべい 2 枚 (100 kcal)
      - プリン 普通サイズ (150 kcal)
      - 大福 1 個 (170 kcal)
      - ドーナツ 半分 (100 kcal)
      - メロンパン 1/3 (130 kcal)
      - チーズケーキ 1/3 (130 kcal)

      ### 200-400 kcal (ご飯系 or デザート系)
      - おにぎり 1 個 (180 kcal)
      - チョコモナカ 1 個 (240 kcal)
      - アイスクリーム 普通 (200 kcal)
      - みたらし団子 3 本 (270 kcal)
      - クッキー 1 袋 (300 kcal)
      - 菓子パン 1 個 (320 kcal)
      - パスタ 半人前 (300 kcal)

      ### 400 kcal 以上 (たっぷり系)
      - ショートケーキ (300 kcal)
      - フラペチーノ (380 kcal)
      - アイスクリーム ダブル (400 kcal)
      - おにぎり 2 個 (360 kcal)
      - カップラーメン 半分 (160 kcal)
      - チーズケーキ (350 kcal)
      - チョコパフェ (450 kcal)
      - ハンバーガー 1 個 (500 kcal)

      ## 出力ルール

      - 必ず suggest_foods ツールを呼び出してください
      - 食べ物は上記データベースから選び、消費 kcal に合った帯を中心に多様な 3 件を選ぶ
      - kcal は実数で
      - label: 食べ物 1 つの kcal が消費 kcal の 50% 未満なら "余裕"、50-90% なら "OK"、それ以上は null
    PROMPT

    # JSON 出力を強制するための tool 定義。
    # tool_choice: { type: "tool", name: "suggest_foods" } と組み合わせて Claude にこのツール呼び出しを強制する。
    TOOL_DEFINITION = {
      name: "suggest_foods",
      description: "今日の消費カロリーに見合う食べ物 3 つを提案する。",
      input_schema: {
        type: "object",
        properties: {
          items: {
            type: "array",
            minItems: 3,
            maxItems: 3,
            items: {
              type: "object",
              properties: {
                name:  { type: "string", description: "食べ物名 (例: チョコモナカ 半分)" },
                kcal:  { type: "integer", description: "1 つあたりの推定 kcal" },
                label: { type: [ "string", "null" ], enum: [ "余裕", "OK", nil ], description: "余裕度ラベル (該当なければ null)" }
              },
              required: %w[name kcal label]
            }
          }
        },
        required: %w[items]
      }
    }.freeze

    # @param estimated_kcal [Integer]
    # @return [Array<CalorieAdviceService::Item>] 3 件
    # @raise [StandardError] API 失敗時 (= 上位 CalorieAdviceService が rescue してフォールバック)
    def self.call(estimated_kcal)
      new(estimated_kcal).call
    end

    def initialize(estimated_kcal)
      @estimated_kcal = estimated_kcal.to_i
    end

    def call
      response = client.messages.create(
        # `system_:` は SDK 側のパラメータ命名 (= Ruby の Kernel#system 衝突回避で末尾 _ が付く)。
        # 公式 anthropic gem 1.36 の MessageCreateParams を参照。
        model:      MODEL,
        max_tokens: MAX_TOKENS,
        system_:    SYSTEM_PROMPT,
        tools:        [ TOOL_DEFINITION ],
        tool_choice:  { type: "tool", name: "suggest_foods" }, # JSON 出力を強制
        messages: [
          { role: "user", content: "今日の消費カロリー: #{@estimated_kcal} kcal" }
        ]
      )

      extract_items(response)
    end

    private

    def client
      @client ||= Anthropic::Client.new(
        api_key:     Rails.application.credentials.dig(:anthropic, :api_key),
        timeout:     TIMEOUT_SEC,
        max_retries: 0
      )
    end

    # response.content から tool_use block を取り出して Item 配列に変換する。
    # tool_choice で suggest_foods 強制しているので必ず tool_use block が含まれるはずだが、
    # 万一ない場合 (= 安全フィルタ作動等) は raise してフォールバックさせる。
    def extract_items(response)
      tool_use_block = response.content.find { |b| b.type == :tool_use }
      raise "No tool_use block in response" unless tool_use_block

      # SDK 1.36 検証済み: tool_use.input は Hash (シンボルキー) で返る。
      # SDK upgrade で形式が変わったら fail-fast で気付ける方がフォールバックも素直に発火する。
      raw = tool_use_block.input
      raise "Unexpected input type: #{raw.class}" unless raw.is_a?(Hash)

      items_data = raw[:items] || raw["items"]
      raise "Invalid items in tool input" unless items_data.is_a?(Array)

      items_data.map do |item|
        raise "Unexpected item type: #{item.class}" unless item.is_a?(Hash)
        CalorieAdviceService::Item.new(
          name:  item[:name]  || item["name"],
          kcal:  (item[:kcal] || item["kcal"]).to_i,
          label: item[:label] || item["label"]
        )
      end
    end
  end
end
