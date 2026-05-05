# Day 3 開発ログ (2026-05-02)

GW 3 日目。Day 1-2 で立ち上げた Rails + 認証基盤の上に、本命 **Apple Shortcuts → Webhook 受信** 経路 (Phase 1) を実装する。同時に sketchy 風テーマで UI を朝のうちに大枠導入し、ホーム dashboard を「Play before signup」(= 未ログインでもデモ表示) で実装、設定画面で webhook_token コピー UI を整える。**5 PR 完走 + テスト 0 → 210 examples** で発表会準備度を一気に 65% まで押し上げた一日。

---

## 🎯 Day 3 の目標

1. Apple Shortcuts → Webhook 受信エンドポイント (Phase 1) を Rails 側で完結させる
2. sketchy 風テーマを朝のうちに大枠導入し、後の dashboard 実装と整合確保
3. README をスクール提出テンプレで全面執筆 (= 要件定義の言語化)
4. 設定画面で webhook_token のコピー / 再生成 UI を整える
5. ホーム dashboard を 4 状態 (guest / android / empty / iphone_with_data) で出し分け
6. 発表会まで残り 4 日のうち、本日中に「最悪 Webhook 未完でもデモモードで成立する」保険を確立

---

## ✅ 達成事項

### 5 PR 完走

| PR | Issue | 内容 | コミット (squash 後) |
|---|---|---|---|
| #30 | (なし) | Claude Design v3 由来の sketchy 風テーマを大枠導入 | sketchy.css 新設 |
| #31 | (なし) | Apple Shortcuts → Webhook 受信エンドポイント (Phase 1) | Migration ×3 + WebhooksController + RSpec 121 examples |
| #32 | (なし) | README をスクール提出テンプレで全面執筆 (要件詰め直し記録) | 370 行 |
| #33 | (なし) | 設定画面で webhook_token のコピー / 再生成を実装 (Phase 3) | SettingsController + Stimulus copy_controller.js |
| #34 | (なし) | ホーム dashboard を 4 状態出し分けで実装 (Play before signup) | HomeController + 4 services + 4 partials + Wireframe v3 由来の SVG dashboard |

→ **5 PR / 3 マージ済み / 2 OPEN レビュー後**。テスト総数 **0 → 210 examples / 0 failures**。

### Apple Shortcuts → Webhook 受信エンドポイント (PR #31、最重要)

本日の本命タスク。スマホから歩数を Rails に POST する経路を Phase 1 (= Rails 側完結) で完成させた。

#### 実装した DB 構造 (Migration ×3)

- `users.webhook_token` (= ユーザー固有の認証トークン、`has_secure_token` で 24 文字 base58)
- `step_records` (= 受信した歩数の永続化テーブル、`recorded_on` + `user_id` の複合 unique)
- `webhook_deliveries` (= 受信時の監査ログテーブル、success / invalid / unauthorized の status と payload を残す)

#### `WebhooksController` の主要設計判断

- **`ActionController::API` 継承**: CSRF 検証で params eager 読み → JSON parse middleware が controller 到達前に 400 を返す問題を、`skip_forgery_protection` 等の禁止 workaround ではなく Rails 標準パターンで回避
- **Bearer token 認証**: `Authorization: Bearer <token>` ヘッダから `User#webhook_token` を `ActiveSupport::SecurityUtils.secure_compare` で照合 (= タイミング攻撃対策)
- **raw body 受信**: ActionController::API なので `request.raw_post` で生 JSON を受け取り、`JSON.parse` で展開
- **配列 upsert**: 1 リクエストで複数日のデータを送れる仕様 (`{records: [{recorded_on:, steps:, ...}, ...]}`)、partial-update セマンティクスでキー欠落を許容
- **監査ログを必ず残す**: 401 / 422 でも `WebhookDelivery` レコードを記録、後追い分析可能

#### RSpec 121 examples

- 正常系: 1 件 / 複数件 / partial-update / 既存レコード更新
- 異常系: invalid token / missing records array / JSON parse error / 負数 steps / 不正な日付フォーマット
- 監査ログ: 全分岐で `WebhookDelivery` が status 込みで記録されることを確認

### Service オブジェクト 4 種 (PR #34、教材性の蓄積)

ホーム dashboard を 4 状態出し分けで実装するために、PORO (Plain Old Ruby Object) パターンで Service を 4 つ新規作成。すべて `.call` クラスメソッドのみ。

| Service | 役割 | 教材ポイント |
|---|---|---|
| `PlatformDetectorService` | UA → `:ios` / `:android` / `:other` | UA 判定の最小実装 |
| `DemoDataService` | 30 日サンプル `StepRecord`-like 配列 | Struct + duck typing、`Random.new` ローカル PRNG |
| `StreakCalculatorService` | 連続日数計算 | 「今日未到着」優しい仕様 (= 当日歩数ゼロでも streak 維持) |
| `CalorieAdviceService` | kcal 帯別の食べ物提案 | 固定リスト → 将来 AI 差し替え可能なインターフェース設計 |

### sketchy 風テーマ導入 (PR #30、UI 並走戦略)

朝の戦略転換で「UI 後回し」から「UI 並走」へ切り替え。Anthropic の **Claude Design** で v3 ワイヤーフレーム取得し、sketchy 風 (= 手書き感のあるカジュアルトーン) を採用。

- `app/assets/stylesheets/sketchy.css` 新設
- 主要コンポーネント: `sketch-navbar` / `sketch-box` / `sketch-btn` / `sketch-toast`
- layout / home / about を sketchy 化
- CLAUDE.md に **スタイル使い分けルール** 追記:
  - sketch-* は **新規実装の正準**
  - Tailwind utility (= flex / grid / mt-4) は引き続き OK
  - daisyUI コンポーネント (= btn / card / navbar / alert) は **新規利用禁止**、既存箇所も触ったタイミングで sketch-* に置換

### README 全面執筆 (PR #32、要件言語化)

スクール提出テンプレで Section 1〜10 を **1 セクションずつ対話で詰めて** 370 行の README を完成。アプリの位置付けが本日明確になった。

#### 確定したアプリの位置付け

- **コンセプト**: 「ずぼらな人」が、入力ゼロで「自分も動ける側だ」と気付けるようになる運動アプリ
- **ターゲット**: ジムも筋トレも行わない通勤通学カジュアル層 (25-40 歳、ハイブリッド勤務、都市部)
- **本質課題**: 「動いていない自分」のセルフイメージ更新 → 本格運動への入り口
- **競合**: あすけん (1 日で挫折した実体験ベース)、差別化は **「入力ゼロ」**
- **機能 3 枠**:
  - MVP: Apple Shortcuts 自動連携 + dashboard + Streak + AI 提案
  - 💰 カロリー貯金システム (本リリース、罪悪感→財務感覚)
  - 🏋️ ガチ運動モード (自転車 / Strava / 心拍 / 体重)
  - 📱 プラットフォーム拡張 (Capacitor + Health Connect で Android 完全対応)

### Settings 画面 (PR #33、Stimulus 2 個目)

- `SettingsController` (= `require_login` で認証必須)
- 3 ステップ + 危険ゾーン UI:
  - Step 1: webhook_token を表示 + コピーボタン
  - Step 2: iPhone Shortcuts の組み立てガイド
  - Step 3: 動作確認方法
  - 危険ゾーン: token 再生成 (= 旧 token 無効化、JS confirm() で確認)
- **Stimulus `copy_controller.js`** (= Day 2 の `flash_controller.js` に続く 2 個目)
  - クリップボード API で webhook_token をコピー
  - 「コピーしました」フラッシュを 2 秒間表示

### ホーム dashboard 4 状態出し分け (PR #34、"Play before signup")

未ログイン状態でもデモデータで dashboard を表示する Linear / Figma 等の SaaS 標準パターンを採用。

| 状態 | 表示 |
|---|---|
| `:guest` | デモデータの dashboard + 「Google でログイン」CTA banner |
| `:android` | デモデータの dashboard + 「Android は今後対応」案内 banner |
| `:empty` | ログイン済みだが歩数記録なし + 「Apple Shortcuts を設定」案内 |
| `:iphone_with_data` | 実データの dashboard + Streak + AI 提案 |

これにより発表会で URL 1 つで「とりあえず触ってみて」が実現可能になった。

---

## 🔥 戦略転換 (= 本日の最大の成果)

### 1. UI 後回し → UI 並走戦略 (朝)

**当初**: 機能実装に集中、UI は後回し。

**転換契機**: Anthropic の **Claude Design** ツールで v3 ワイヤーフレームを取得。後の dashboard 実装と整合させるなら、UI の骨子を先に固める方が手戻り少ない。

**結果**: sketchy 風テーマを朝のうちに大枠導入 (PR #30)、後の dashboard 実装 (PR #34) と整合確保。Tailwind/daisyUI 寄りだった既存実装も sketch-* に置換する方針確定。

### 2. データソース戦略の確定 (昼)

ユーザー (= 開発者本人) は **Android ユーザー** である事実が判明。Web アプリから Android のヘルスデータを自動取得する手段を `api-researcher` サブエージェントで深掘り調査:

| 候補 | 結果 |
|---|---|
| Health Connect (Android 標準) | **Web からアクセス不可** (= Android SDK 専用) |
| Google Fit REST API | **新規プロジェクト登録不可** (= 2024-05〜ブロック済) |
| Tasker / MacroDroid / Automate | 課金 + 設定難 → カジュアル層に届かない |
| Capacitor + Health Connect | 4 日締切に乗らない (= 1 週間以上) |
| Google Takeout 手動 ZIP | 動くが手動操作要 |
| Strava | コンセプトとズレる + 4 日で OAuth 重い、格下げ確定 |
| **案 E: 割り切りデモモード** | **採用** (= スクール内部発表 + 「制作中」を誠実に告知) |

→ 「**Web アプリから Android のヘルスデータを自動取得する手段は 2026-05 時点で公式には存在しない**」が結論。本リリース v1.0 で Capacitor + Health Connect ハイブリッドアプリ化を最優先タスクに据える方針 (= README Section 8 / Section 9 で明記)。

### 3. "Play before signup" 採用 (午後)

**元案**: 未ログイン = ログインカード、ログイン済み = dashboard。

**転換**: 未ログインでも dashboard を **デモデータで表示** (= Linear / Figma 等の SaaS 標準)。

**副次効果**: Android タスク (元別 PR 予定) を Home dashboard PR に統合できた。

**結果**: 発表会で URL 1 つで「とりあえず触ってみて」を実現。**「最悪 Webhook 未完でもデモモードで成立する」保険** を本日中に確立。

---

## 🧠 重要な技術的判断

| 判断 | 理由 |
|---|---|
| `WebhooksController` を `ActionController::API` 継承 | CSRF 検証で params eager 読み → JSON parse middleware が controller 到達前に 400 を返す問題を Rails 標準パターンで解決 (`skip_forgery_protection` 等の禁止 workaround とは別物) |
| `WebhookDelivery` 監査ログテーブル採用 | MVP に過剰に見えるが、外部連携の初手では「何が来たか / なぜ落ちたか」を生で残す価値がコストを上回る |
| 設定画面に sketchy モーダル化を見送り (JS confirm() で代替) | MVP では JS confirm() で十分、UI 専用 modal 実装コスト > リスク低減効果 |
| Demo data の `Struct` + duck typing | 継承や `ActiveModel` に逃げない潔さ、`StepRecord` と同一インターフェース |
| `Random.new(SEED)` ローカル PRNG | Puma マルチスレッド環境で `srand` のグローバル副作用を回避 |

---

## 🤝 当日採用した運用パターン

- **3 者並列レビュー必須** (= code / strategic / design): 5 PR 全てで実施。指摘総数 約 30 件、採用 約 25 件
- **対話ベース要件詰め**: README Section 2-10 を 1 セクションずつ詰めた経験は、今後の他機能開発でも踏襲したい
- **`gh pr create` の Test plan 必須**
- **「便乗修正」は PR description で明示** (例: PR #33 で `home_spec.rb` regression を便乗修正、その旨明記)
- **マージ順序の明示** (例: PR #34 で「PR #33 を先にマージしてから本 PR を」を明記、Settings の banner リンクが 404 にならないよう)

---

## 🎯 発表会準備度 (推定)

**約 65%** (本日の進捗で +50%):

- ✅ アプリの顔 (= ホーム dashboard) 完成
- ✅ Apple Shortcuts Webhook 受信 (= Rails 側完結)
- ✅ 設定画面 (= token コピー UI)
- ✅ README (= 要件説明資料)
- ⏳ iPhone 実機テスト (= 一番不確実、Phase 2 = Day 4)
- ⏳ デプロイ + 公開 URL (= Day 5 想定)
- ⏳ デモシナリオ (= Day 6)

**「最悪 Webhook 未完でも発表会はデモモードのみで成立する」** という保険を本日中に確立できたのが最大の戦略成果 (strategic-reviewer 評)。

---

## 📌 学び (Day 3 で得たもの)

### Webhook 実装

- **`ActionController::API` 継承で CSRF 検証問題を Rails 標準パターンで回避**: `skip_forgery_protection` 等の禁止 workaround を使う前に、Rails の用意しているレイヤを思い出す
- **監査ログテーブルは MVP でも入れる**: 外部連携の初手では「何が来たか / なぜ落ちたか」を生で残す価値がコストを上回る
- **partial-update セマンティクス**: `payload[key]` がないキーは更新せず維持。「全フィールド送信必須」と「部分送信 OK」の設計判断は API の使いやすさを大きく変える

### Service オブジェクト

- **PORO `.call` クラスメソッドだけで十分**: ActiveSupport::Concern も ActiveModel も継承不要、単純な式オブジェクトで Service の責務を表現
- **Demo data は Struct + duck typing で**: ActiveRecord と同じインターフェースを Struct で再現、view 側は受け側の型を意識しない設計
- **`Random.new(SEED)` でローカル PRNG**: グローバル `srand` を avoiding、マルチスレッド環境での予期しない副作用を防ぐ

### 戦略

- **「最悪のフォールバック」を最初に確立する**: デモモード (= Webhook 未完でもデモ表示で発表会成立) を確立した時点で、心理的に余裕ができて本命タスクに集中できる
- **api-researcher の威力**: Web からの Android ヘルスデータ取得手段を **網羅的に調査** することで、「公式には存在しない」結論に確信を持って到達。机上検討より一段階強い意思決定支援
- **Claude Design の使い所**: ワイヤーフレーム提供 → デザイン迷子を脱出。実装フェーズの初手で UI 骨子を確定すると後の手戻り激減

### コードを最強の伝達手段にする

- レビュー反映コミットは **「指摘との対応関係」をコミットメッセージに `[code-reviewer]` / `[design-reviewer]` のカテゴリ別に列挙する** スタイルが模範解答
- 設計判断は PR description より **コード内のコメント (= 永続化)** で残す方が、後で読む人に届く

---

## 📊 統計

- マージした PR: 3 本 (= #30, #31 が当日マージ。#32-#34 は OPEN レビュー後)
- 起票した PR: 5 本
- 全体 spec: **0 → 210 examples** (= +210)
- 完成した Service: 4 個 (= PlatformDetector / DemoData / StreakCalculator / CalorieAdvice)
- 確定した戦略転換: 3 件 (= UI 並走 / データソース / Play before signup)

---

## How to apply

- **Day 4 (= 翌日 5/3)**:
  - OPEN PR 3 件 (#32, #33, #34) のマージ確認 (= マージ順序: #32 → #33 → #34、#33 を先にマージしないと #34 の banner リンクが 404)
  - **Phase 2 着手**: iPhone 実機 + ngrok で Apple Shortcuts 組み立て → 200 OK + step_records 記録確認
- **Webhook 関連の不具合**:
  - `WebhookDelivery` テーブルを最初に grep して「実際にリクエストが Rails に到達しているか」を確認
  - 401 → token 不一致 / Bearer prefix の有無 / Authorization ヘッダの末尾空白 (= Day 4 夜に学んだ知見、別 dev-log)
- **新機能を追加する時**:
  - PORO `.call` パターンで Service object を切り出す
  - 監査ログがあれば残す
  - Test plan を PR description に必ず書く
