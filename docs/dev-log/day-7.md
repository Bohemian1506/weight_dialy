# Day 7 開発ログ (2026-05-05、発表会前日)

GW 6 日目、発表会前日。Day 6 (= 5/4) の Render 本番デプロイ + Anthropic Claude 接続を経て **本物の AI が production で動く weight_dialy** に到達した翌日、本日は **発表会前に必須の項目を確実に押さえる** + **scope 整理を徹底する** 1 日。Day 6 で寝かせた PR #82 を起点に、退会機能 → プライバシーポリシー → 食品換算動的化を順次実装。各機能で 3 者並列レビューを 2 ラウンドずつ回し、13 件の別 Issue を起票して「やりたいけど今やらない」を可視化した。さらに **Day 3-7 dev-log の後追い整備 + dev-log 運用ルール化** で教材性インフラを完成。終盤は **OPEN Issue 棚卸し + リファクタ 4 件 (#85 #86 #45 + home_controller 集約) + SQL 集計化 (#72) + 法務記述強化 (#88 #89) + sketchy danger 体系の三色一致 polish 連鎖 (#105 #106 #116)** で polish + perf + 法務まで消化。**夜は Issue #40 (Capacitor + Health Connect Android 対応) に着手**、子 Issue 8 件 (#119-#126) に分解 + 起票後、子 1 (Capacitor 8.3.1 scaffold) → 子 2 (`@capgo/capacitor-health` 導入 + Privacy Policy URL 設定) → 子 3 (動的パーミッションフロー Stimulus controller) → 子 4 (歩数 / 距離 / 階段の取得ロジック) → 子 5a (手動同期ボタン + Webhook POST、**MVP 終端**) を順次マージ、**Issue #40 B スコープの中核機能達成** (= 「Android で歩く → アプリで同期 → ホーム画面に反映」のループ成立)。深夜は子 6 (= 実機 E2E、Android Studio + Pixel 7 エミュレータ) に着手、**4 ラウンドの追加 fix** (= PR #140 #142 #146 #147、minSdk / Capacitor appendUserAgent 既知バグ / Rails allow_browser × WebView UA / OAuth Custom Tabs 戻り) を経て **Capacitor アプリ内 OAuth ログイン (Custom Tabs 経由) 完走**。さらに深夜延長で **Phase 2a (PR #149 = appUrlOpen handler) + Phase 2b (PR #151 = AssetLinks verify)** を実装、ただし AVD 動作確認では **AssetLinks verify が Custom Tabs 経由 OAuth callback には効かない可能性**が浮上 (= 仮説、実機検証で確定予定)。**27 PR マージ + 31 Issue 起票 + 25 Issue close** で、発表会前の最終調整に到達 + Android v1.0 の道半ば (= 子 6 動作確認は明朝再挑戦)。

セッションの戦略テーマ: **「発表会前日、必須項目を確実に押さえる」+「設計事前 3 者レビューによる手戻り回避」**

---

## 🎯 Day 7 の目標

1. Day 6 で寝かせた PR #82 (= webhook 数値型ガード) のマージ確認
2. **退会機能** の実装 (= プライバシーポリシーの前提)
3. **プライバシーポリシー / 利用規約** ページの実装 (= スクール公開フォーム提出時の URL 求められる前提)
4. **食品換算の動的化** (= 下段 4 カードのハードコード「アイス 1 個ぶん」を日替わりランダムに)
5. memory 永続化 (= Day 7 全体サマリー + feedback 3 件)
6. 残時間で polish 系 / 別 Issue 整理
7. dev-log 整備 (= Day 3-7 を後追いで書き起こし + 運用ルール化)

---

## 🏆 達成したこと (= 計 14 PR + 15 Issue 起票 + 17 Issue close)

### マージ済み PR (= 14 本)

| PR | Issue | 内容 |
|---|---|---|
| #82 | #52 | webhook 数値型ガード + accepted_count 記録 (= Day 6 寝かせ分、Day 7 朝にマージ) |
| #87 | #84 | **ユーザー退会機能** (= GitHub 方式名前入力モーダル、cascade delete、即時、ログアウト遷移) |
| #92 | #38 | **プライバシーポリシー / 利用規約ページ** (= /privacy, /terms、ヘルスデータ免責、第三者提供明示) |
| #97 | #71 | **下段 4 カード食品換算動的化** (= 軽食 10 種類 + ランダム + 絵文字 + 1 日固定シード) |
| #98 | #96 | CalorieEquivalentService リファクタ (= MIN_KCAL 定数化 + Item の private_constant) |
| #100 | #95 | 食品換算 count 上限キャップ + 再抽選 (= max_count=5、shuffle で順序確定 + フォールバック) |
| #101 | – | **Day 3-7 開発ログを追加** (= 5 ファイル / 約 83KB / 1,407 行、後追いまとめ書き) |
| #102 | – | **dev-log 運用フローを CLAUDE.md に追加** (= マージ後の必須作業として明記、Day 3-7 反省由来) |
| #104 | #85 | refactor: webhook_deliveries / step_records の FK に `on_delete: :cascade` 追加 (= Rails dependent と DB FK の二重防衛) |
| #107 | #86 | refactor: sketchy theme に `--danger` カラートークン + 専用クラス整備 (= `#cc0000` ハードコード排除、`-soft` で 2 段階 intensity) |
| #108 | #45 | chore: postCreateCommand で `mise trust` を自動化 (= container recreate 後の手動作業を省く、Day 4 反省由来) |
| #110 | – | refactor: home_controller のロジックを `BuildHomeDashboardService` に集約 (= `Data.define` Result、controller skinny 化、PR 分割の前段) |
| #111 | #72 | perf: home_controller の step_records 取得を SQL 集計に切り替え (= `CalorieSavingsService.call_for_user(user)` 追加、全期間 records 配列 load 排除) |
| #113 | #88 #89 | polish: 法務記述強化 (= 個情法 32 条「事業者表示」+ 消契法 8 条「故意・重過失除外」、改訂履歴も同時更新) |
| #115 | #105 #106 | polish: トークン再生成タイトルを `sketch-h-danger` 統一 + CLAUDE.md に危険度クラス命名規約追記 |
| #117 | #116 | polish: `sketch-box-danger-soft` のボーダーを半透明赤 (= `--danger-soft-border` rgba 35%) にして背景・タイトル・ボーダーで赤系三色一致 |
| #127 | #119 | feat: Capacitor 8.3.1 初期化 + `server.url` を本番 URL (`https://weight-dialy.onrender.com`) にラップ (= Issue #40 子 1、Android v1.0 出発点) |
| #130 | #120 | feat: `@capgo/capacitor-health` 8.4.9 導入 + Privacy Policy URL を `strings.xml` に設定 (= Issue #40 子 2、Health Connect 連携プラグインの基盤整備) |
| #133 | #121 | feat: Health Connect 動的パーミッションフロー実装 (= Issue #40 子 3、Stimulus controller 経由で Capacitor 検知 + permission チェック / リクエスト / フォールバック UI、Web 版影響ゼロ) |
| #136 | #122 | feat: Health Connect から歩数 / 距離 / 階段データを取得 (= Issue #40 子 4、`queryAggregated` API + 個別フォールバック + JST timezone 修正) |
| #137 | #123 | feat: 手動同期ボタン + Webhook POST フロー MVP (= Issue #40 子 5a、`/webhooks/health_data` への POST + フィールド名変換 + status 視認性向上、**Issue #40 B スコープ MVP 達成**) |
| #140 | – | fix: Capacitor アプリ WebView を allow_browser から bypass + minSdk 26 に上げる (= 子 6 動作確認で発覚した 2 ブロッカー fix、Rails 8 × Capacitor 統合) |
| #142 | – | fix: Capacitor `appendUserAgent` 既知バグを `overrideUserAgent` workaround、`wv` 保険で二重防衛 (= 子 6 動作確認 2 ラウンド目、GitHub Issue #4886 #6037 由来の沼) |
| #146 | – | fix: `/auth/` パスを allow_browser から bypass (= 子 6 動作確認 3 ラウンド目、Google "In-App Browsers Are Not Allowed" 2021 ポリシー対応 OAuth Custom Tabs 経由のため) |
| #147 | – | fix: Mobile Chrome UA も whitelist 追加 (= 子 6 動作確認 4 ラウンド目、Custom Tabs から `/` に戻った時の UA 対策、三重防衛) |
| #149 | – | feat: Phase 2a — Custom Tabs から Capacitor アプリへ deep link で帰還 (= appUrlOpen handler、autoVerify="false") |
| #151 | – | feat: Phase 2b — AssetLinks verify で deep link を seamless 化 (= public/.well-known/assetlinks.json + autoVerify="true") |

### close した Issue (= 25 件)

- **#39 発表会デモシナリオ準備** — 本人プレゼンないので close (= スクープ外と判断)
- **#35 ngrok 動作確認** — Day 5 で完了済みだったが OPEN 残存だったので close
- **#58 #73 #75** — PR #80, #81 で実装済みだが自動 close trigger 不発で残っていた、Day 7 終盤で手動 close (= 実装コードの存在を grep 確認後)
- **#52 #84 #38 #71 #96 #95** — PR マージで自動 close
- **#85 #86 #45** — リファクタ系 3 件、PR #104, #107, #108 で close
- **#72** — perf 改善 (= SQL 集計化)、PR #111 で close
- **#88 #89** — 法務記述強化、PR #113 で close
- **#105 #106** — sketchy `--danger` フォローアップ (= タイトル赤化 + 規約追記)、PR #115 で close
- **#116** — sketchy danger-soft ボーダー半透明赤化 (= 三色一致 polish 連鎖の最終ピース)、PR #117 で close
- **#119** — Capacitor 初期化 + server.url wrap (= Issue #40 子 1、Android v1.0 出発点)、PR #127 で close
- **#120** — `@capgo/capacitor-health` 導入 + Privacy Policy URL 設定 (= Issue #40 子 2、Health Connect 連携基盤)、PR #130 で close
- **#121** — Health Connect 動的パーミッションフロー (= Issue #40 子 3、Stimulus controller 経由)、PR #133 で close
- **#122** — Health Connect 歩数 / 距離 / 階段データ取得 (= Issue #40 子 4、queryAggregated API)、PR #136 で close
- **#123** — 手動同期ボタン + Webhook POST フロー MVP (= Issue #40 子 5a、B スコープ MVP 達成)、PR #137 で close

### 起票した Issue (= 15 件 + Issue #40 子 Issue 8 件 + 派生 polish 4 件 + Issue #8 追記)

- #83 webhook error_message 日本語化
- #85 webhook_deliveries / step_records FK `on_delete: :cascade`
- #86 sketchy theme `--danger` カラートークン
- #88 プライバシーポリシー「事業者の表示」(= 運営者表記)
- #89 利用規約「免責事項」消費者契約法 8 条対応
- #90 Settings ポリシーリンク配置変更
- #91 改訂履歴セクション構造化
- #93 AI 提案カードを累計貯カロリーベース化
- #94 食品換算「next」案 (= 同スケール内次の食品ゲーミフィケーション)
- #95 食品換算 count 上限キャップ → **PR #100 でマージ済**
- #96 CalorieEquivalentService 定数化リファクタ → **PR #98 でマージ済**
- #99 食品換算フォールバック文言の読みづらさ (= 食品 name 構造改善)
- #105 トークン再生成ボックスのタイトル色統一 (= sketchy `--danger` フォローアップ) → **PR #115 でマージ済**
- #106 CLAUDE.md スタイル規約に危険度クラス命名方針を追記 (= sketchy `--danger` フォローアップ) → **PR #115 でマージ済**
- #116 `sketch-box-danger-soft` のボーダーを半透明赤化 (= PR #115 design-reviewer 任意提案、三色一致) → **PR #117 でマージ済**

#### Issue #40 子 Issue 8 件 (= Capacitor + Health Connect Android 対応の分解、夜セッションで起票)

- #119 Capacitor 初期化 + Rails server.url wrap (= 本番 URL 固定) → **PR #127 でマージ済**
- #120 `@capgo/capacitor-health` 導入 + AndroidManifest に Health Connect permission 3 種類宣言
- #121 Health Connect 動的パーミッションフロー (= 許可ダイアログ + 拒否時フォールバック)
- #122 歩数 / 距離 / 階段の 3 種類データ取得ロジック
- #123 手動同期ボタン + Webhook POST フロー (= フェーズ 1 = MVP)
- #124 WorkManager によるバックグラウンド定期同期 (= フェーズ 2 = 自動化、A→C 段階アプローチの上乗せ)
- #125 Android エミュレータ + 実機 (Pixel) E2E
- #126 デモ APK ビルド + sideload 手順

#### 派生 polish (= PR #127 design レビューより)

- #128 Capacitor splash 背景色を sketchy theme `--paper` (`#fbf8f1`) 単色に置き換え (= 発表会前 polish 候補、子 1 のスコープ膨張防ぐため別 Issue 化)
- #131 `/privacy` に Android Health Connect 経由の取得情報を明記 (= Google 規約対応、PR #130 design レビュー由来、発表会前必須)
- #134 Health Connect セクションの UI 微調整 (= ボタン文言「歩数を取得する」検討 + 見出し絵文字 📱 削除検討、PR #133 design レビュー由来、v1.1)
- #138 Webhook POST UX 改善 (= 401 → Settings 誘導 + HTTP status 別日本語化、PR #137 strategic+design レビュー由来、v1.1)
- #143 SNS 内蔵ブラウザ (LINE / Twitter 等) で OAuth ログインが詰まる問題への案内 (= PR #142 design レビュー由来、v1.1)
- #144 Capacitor アプリ時に Settings の Health Connect セクションを最上部 / 中央に誘導 (= PR #142 design レビュー由来、v1.1)
- #145 Capacitor アプリ初回起動時の FOUT (フォントちらつき) 対策 (= PR #142 design レビュー由来、v1.1)
- #150 deep link ダイアログで「ブラウザで開く」を誤選択した場合の回復導線 (= PR #149 design レビュー由来、v1.0 polish)

#### v1.0 最重要 (= 子 6 完全完走の鍵、Phase 2a/2b 実装済 → 実機検証待ち)

- **Phase 2a 実装済 (PR #149)**: appUrlOpen handler、autoVerify="false" で「アプリで開く?」ダイアログ経由の予定
- **Phase 2b 実装済 (PR #151)**: AssetLinks verify で seamless 化、ただし AVD 動作確認では **deep link 動作せず**
- **明朝の検証ポイント**: 仮説 1 (= verify 待ち反映) / 仮説 2 (= AVD 制約、実機テスト) / 仮説 5 (= Custom Tabs 内 callback は AssetLinks 対象外)
- **Phase 3 候補** (= Phase 2b 失敗時): `@capacitor/browser` plugin で OAuth フロー全体を Capacitor 制御
- **Mobile Chrome bypass (PR #147) 削除** = deep link 実装完成後不要、`allow_browser` 本来の効果を取り戻す

- (Issue #8 への追記: 「初回ログイン時の同意モーダル」)

---

## 🧠 教訓ハイライト (= 7 件、本日確立)

### 1. 不可逆操作 PR は rescue + redirect + 失敗系 spec の最低セット

退会機能 (= PR #87) で `current_user.destroy!` 失敗時の rescue 無くて 500 + セッション残留 Blocker を踏んだ。code-reviewer が発見、修正 commit で対応。

→ memory `feedback_irreversible_action_pr_pattern.md` 化。削除 / 退会 / API 課金など不可逆操作には以下を最低セットとして揃える:
1. `rescue` (= 例外 catch して 500 + セッション残留を防ぐ)
2. `redirect_to + flash[:alert]` (= ユーザーに失敗を伝える、UX を崩さない)
3. 失敗系 spec (= 実装と spec をセットで作る)

### 2. ランダム性 × テスタビリティパターン

食品換算 (= PR #97) で以下のパターンを確立:
1. `Random.new(seed)` を使う (= グローバル `srand` を避ける、他 spec / 他 service への副作用ゼロ)
2. `seed:` キーワード引数で外部注入可能 (= テストで固定値渡せる、確定的になる)
3. シード値は `Date.current.to_s.bytes.sum` 等の安定値 (= `String#hash` は Ruby 1.9+ で実装依存、プロセス起動毎に変わる)
4. spec で「グローバル乱数状態への副作用なし」を検証 (= `srand(N)` → `rand` → `Service.call` → `rand` の前後一致)

→ strategic-reviewer から「教材として白眉」と評価された再利用可能テンプレ。memory `feedback_random_with_seed_testability.md` 化。

### 3. CSS 副作用回避は専用クラス切り出し

食品換算で ellipsis を `sketch-small` 全体に当てると他箇所 (= 「これまでの合計」「Powered by Claude」「(近日公開予定)」等) で折り返し期待される文に影響。**専用クラス `sketch-food-equivalent` に切り出して限定適用**。

→ 教訓: ユーティリティクラスに副作用出る修正は **全体に当てず専用クラスを切る**。

### 4. 元 Issue 大幅逸脱時は別 Issue 化 + 元 Issue 書き換え

Issue #71 「貯カロリーに食品換算」が議論で「下段 4 カード動的化」に大幅 scope 変更。AI 累計ベース化 (= #93) と「next」案 (= #94) を別 Issue 化、元 Issue #71 のタイトル + 本文を書き換えて整合維持。

→ 教訓: 議論で scope 変わったら **元 Issue を編集 (= 履歴汚染しない)、派生は別 Issue 起票**。

### 5. 設計事前 3 者レビュー (= 手戻り回避)

Issue #71 で **実装前** に 3 者レビューを走らせ、「next 案見送り」「食品リスト平易化」「絵文字付加」「`bytes.sum` シード」を確定 → 実装時の手戻り回避。

→ memory `feedback_always_three_reviewers.md` の応用。教訓: **大きい設計判断 (= 食品リスト 10 種類選定 + ランダム抽出 + 「next」案) は事前にレビューを通すと、実装時の Blocker 出現確率が下がる**。

### 6. PR 鮮度管理 (= 寝かせるとリスク蓄積)

PR #82 を 1 日寝かせた間に main に 3 PR (= #79-#81) マージ → 干渉懸念で再レビュー必要に。

→ 教訓: **「寝かせた PR は main 進化分だけリスク蓄積」を意識**、寝かせるなら最終マージ前に必ず再レビュー。

### 7. polish の投資判断は「観客の画面占有率 × 不信度」

strategic-reviewer 由来 (= PR #100)。「バナナ 11 本ぶん」のような表示は、デモ画面に映る確率 (= 観客の目に入る) × カジュアル層の不信度 (= 「11 本食べないでしょ」と笑い or 違和感) で投資価値が決まる。

→ 教訓: **両軸が高い polish は発表会前にやる価値あり**、低い polish (= 内部実装の細かい整備) は発表会後で OK という判断軸。

---

## 🔥 つまずき / 学び

### つまずき 1: rails-implementer が spec を書かない

退会機能と食品換算で rails-implementer が「spec は test-writer の領分」として spec 未作成。`.claude/agents/` 定義を踏まえると正しい挙動。

→ **実装後は test-writer に明示的に依頼が必要**。次回から rails-implementer に prompt する時、spec を含むなら明示する or 標準ワークフローとして test-writer 別途呼ぶ。

### つまずき 2: PR #82 のレビュー時間ズレ (= 記憶ベース記録の限界)

memory `project_day4_evening_ai_completion.md` には「~15:00」と書かれていたが、ユーザーは「16 時前にやった」と訂正。historical 文書の時間記録は記憶ベースで誤差が出る。

→ 次回からは git log の commit 時刻を参照して正確に書く。

### 学び 1: Issue 起票による scope 整理の効果

13 件の別 Issue 起票で「やりたいけど今やらない」を可視化。**scope 拡大の罠を避け、発表会前の集中力維持**。発表会後の v1.1 polish タスクとして自然に積まれた状態。

### 学び 2: 設計事前レビュー → 修正コスト最小化

Issue #71 で事前レビューを走らせた結果、実装後 1 ラウンド目のレビューで重大 Blocker が出ず (= design の必須 2 件のみ)、修正コスト最小化。退会・プライバシーポリシーは事前レビューなしで実装後に Blocker 多数 → **設計事前レビューの ROI が高い**。

### 学び 3: 痛みを感じた直後にルール化する (= dev-log 運用ルール)

Day 3-7 (= 5/2-5/5) を発表会前日に **後追いで 1,407 行書く** 痛みを直接の動機として、「マージ直後に dev-log 追記」を運用ルール化 (= PR #102)。strategic-reviewer 評: 「痛みが新鮮なうちに永続化するのは正しいタイミング」。本 day-7.md への追記が **新ルールの初適用**。

### 学び 4: 「Closes」キーワードでも自動 close されないことがある

PR #80 description に `Closes #48 #58 #75` と明記されていたが、PR マージ後に **#48 のみ自動 close、#58 と #75 は OPEN 残存**。同様に PR #81 の `Closes #70 #73` でも #70 のみ close、#73 OPEN 残存。

→ 推測: PR description を後から編集すると trigger 不発、または GitHub 側の処理タイミング問題。**OPEN Issue 棚卸し時は「実装コード grep + 手動 close」を必ず実施**するルールに。Day 7 終盤の棚卸しで 3 件 (#58, #73, #75) を手動 close で消化。

### 学び 5: リファクタ 3 件まとめて短時間勝負 (= Day 7 終盤フェーズ)

OPEN リファクタ系 6 件のうち、**「すぐ終わる + 教材性中」順** に #85 → #86 → #45 を 1 時間半で消化。各々が独立スコープのため、PR を分けて教材性 + レビュー単位明確化を維持。共通の dev-log 追記は本 PR (= まとめ追記) で対応。

教訓: 短時間勝負の polish フェーズは **1 PR 1 主題 + dev-log まとめ追記** が効率的。CLAUDE.md「適用範囲」に明記された運用裁量内で、リファクタ 3 件 + 1 dev-log PR の構成。

### 学び 6: 大きいリファクタは PR 分割で安全に進める

home_controller リファクタ + Issue #72 (= SQL 集計化) を当初 **1 PR でやる予定**だったが、3 者並列事前レビューで「PR 分割推奨」一致 → 分割実行。

- **PR #110**: `BuildHomeDashboardService` 新設 (= 純粋リファクタ、挙動変更ゼロ)
- **PR #111**: `CalorieSavingsService.call_for_user(user)` 追加 (= SQL 集計化)

教訓: **挙動変更を伴うリファクタは「集約」と「最適化」を別 PR にする**と、回帰時の切り分けが容易 + 各 PR のレビュー単位が明確 (= strategic-reviewer 提案を採用)。発表会半日前で 1 PR にまとめるリスクを回避できた。

### 学び 7: 代替パターンの探索は事前レビューに任せる

home_controller リファクタの事前レビューで「私 (= ユーザー) の知らない解決方法があれば」と要望 → strategic-reviewer から 5 種類のパターン提示:

| パターン | 適合度 |
|---|---|
| Service + Result Struct (現提案) | ★★★★☆ |
| Query Object | ★★★☆☆ |
| **ViewModel (`Data.define`)** | ★★★★☆ ← 採用エッセンス |
| Decorator | ★☆☆☆☆ (却下) |
| Interactor / Operation gem | ☆☆☆☆☆ (却下) |

教訓: **設計判断時は「他のパターンないか?」を必ずレビュアーに問う**と、`Data.define` (Ruby 3.2+) のようなモダン技術を発見できる。Service と ViewModel の中間解として `Data.define` を採用、Struct より immutable で教材性 ◎。

### 学び 8: design-reviewer 任意提案も即起票即実装の連鎖 polish で消化

PR #115 (= Issue #105 #106) のレビューで design-reviewer が **任意提案** として「`sketch-box-danger-soft` のボーダーを半透明赤にして三色一致させる」を出した。これを Issue #116 として即起票 → 即実装 → PR #117 でマージという 30 分の連鎖で消化。

- **指摘 → Issue 化 → 実装** をワンセッション内で閉じることで、レビュアーの観察力を活かしきる
- Issue として残すことで「なぜこの修正に至ったか」(= 三色一致のデザイン哲学) が永続化される
- 連鎖 PR (= #115 → #117) は親子関係が PR description で読み取れるため、後輩が「設計が育つ過程」をトレースできる

教訓: **任意提案も「軽くて教材性ある」かつ「時間に余裕ある polish フェーズ前提」なら即連鎖で消化する**と、後で「やり残し Issue」が積み上がらず、かつデザイン哲学 (= 強度差は不透明度で表現) が CSS コメント + Issue + dev-log の 3 箇所に永続化される。**機能未実装が残っている時は後回し** (= スコープ外として別 Issue 積み)。「サクッとマージ」の判断は短時間勝負ほど効くが、判断軸は学び 7 の「観客の画面占有率 × 不信度」と噛み合わせる。

### 学び 9: Capacitor 8 vs 7 のバージョン選択 (= Node 22+ 強制 vs エコシステム成熟度)

Issue #40 子 1 (PR #127) で Capacitor 初期化時に **Node 22+ 必須** という制約に遭遇。host (= Node v20) で動かず、devcontainer (= Node v22 mise 管理) でしか動かない状態。判断ポイントは:

| 案 | 内容 | メリット | デメリット |
|---|---|---|---|
| Capacitor 7.6.2 LTS | Node v18+ で動く | host でも動く、エコシステム成熟、日本語記事多 | 最新ではない、教材性わずかに劣る |
| Capacitor 8.3.1 latest | Node 22+ 必須 | 最新、教材性 ◎ | devcontainer 必須、`@capgo/capacitor-health` 8 対応未確認 |

**プロセス**:
1. ホストで動かそうとして Node v20 → エラー
2. Capacitor 7 にダウングレード (= 暫定回避)
3. ユーザーが「C 挑戦 (= devcontainer Node v22)」を希望 → VS Code 起動 → script/run で確認 → v22 動作確認
4. Capacitor 8 に戻す → 正常動作

**教訓**:
- **環境制約は早めに表面化させる** (= host vs devcontainer の切り分けを最初の install 時点で確認、ハマってからではなく)
- **エコシステム未検証リスクは「次の Issue 着手時に最優先確認」で回収** (= 子 2 着手時に `@capgo/capacitor-health` の Capacitor 8 対応を確認、非対応なら 7 にロールバック)
  - **事後検証結果 (= 子 2 PR #130)**: `@capgo/capacitor-health` 8.4.9 の `peerDependencies` は `@capacitor/core: ">=8.0.0"` (= Capacitor 8 専用、7 では動かない)。子 1 で 8 を選んだ判断が結果として正解、ロールバック対応は不要に
- **devcontainer 起動 = VS Code 必須**: `script/run` は docker 実行中の container を検知するヘルパー、VS Code から Reopen in Container しないと動かない

### 学び 10: scaffold PR の見せ方 (= 「自動生成物 vs 人間判断」を分離)

PR #127 は 56 files / 2150 insertions だが、レビュー対象の本質は `capacitor.config.json` (= 9 行) + `package.json` (= 7 行) の 2 ファイルのみ。残り 53 ファイルは `npx cap add android` の自動生成物。

**strategic-reviewer の指摘**: 「scaffold PR は『自動生成物 vs 人間判断』を PR 本文で分離して書くと、レビュアーが見るべき箇所 (= server.url と App ID 2 行) が一目で分かる。56 files でも怖くない見せ方の型」。

**教訓**: 大量自動生成 PR では、PR description で「人間判断ポイント」を明示的に取り出して箇条書き化する。レビュアーの認知負荷を下げ、レビュー速度 + 質が両立。実例は **PR #127 description の「変更内容」セクション** (= server.url 設定 + App ID 決定 + allowNavigation の 3 ポイントを箇条書き分離) を参照。

### 学び 11: cap add android の placeholder ファイルは手動修正必須

`npx cap add android` が生成する Android プロジェクト一式には **placeholder のままでは破綻する** ファイルが含まれている (= code-reviewer + design-reviewer が両方検出):

| ファイル | placeholder | 修正必要な値 | 検出者 |
|---|---|---|---|
| `androidTest/.../ExampleInstrumentedTest.java` | `package com.getcapacitor.myapp;` + `assertEquals("com.getcapacitor.app", ...)` | `com.weightdialy.app` | code-reviewer (Blocker) |
| `test/.../ExampleUnitTest.java` | `package com.getcapacitor.myapp;` | `com.weightdialy.app` | code-reviewer (Blocker) |
| `res/values/strings.xml` (`app_name`) | `weight_dialy` (= cap init 時の引数そのまま) | `weight daily.` (= Web 版ブランド名) | design-reviewer (発表会前) |

**教訓**: `cap add android` 直後は **必ず以下を手動チェック**:
1. `androidTest/` と `test/` 配下のパッケージ宣言 + assertEquals 内のパッケージ名
2. `strings.xml` の `app_name` / `title_activity_main` (= ホーム画面表示、ブランド整合)
3. `res/values/colors.xml` の有無 (= 未生成なら `colorPrimary` 等が AppCompat フォールバック、後で polish)

これらは scaffold PR 内で潰すべき (= 後続 Issue でフォローしようとすると忘れる)。

### 学び 12: ライブラリ採用時は同梱 AndroidManifest / Info.plist を README より先に grep する

Issue #40 子 2 (PR #130) で `@capgo/capacitor-health` 導入時、子 Issue 本文の予定 (= AndroidManifest に Health Connect permission 3 種類追加) と実態が乖離。

**4 行構造で経緯を残す** (= strategic-reviewer 提案):

1. **予定 (= 子 Issue #120 本文)**: AndroidManifest に `READ_STEPS` / `READ_DISTANCE` / `READ_FLOORS_CLIMBED` の 3 permission を追加
2. **着手で判明**: プラグイン同梱 `node_modules/@capgo/capacitor-health/android/src/main/AndroidManifest.xml` に既に **42 permission 宣言済み** (= READ/WRITE × 21 データ型)。Capacitor のマニフェストマージ機構で自動結合 → アプリ側で重複宣言不要 (= プラグイン README 「Your app does not need to duplicate them」)
3. **実態**: 必要だったのは **Privacy Policy URL 設定** (= Health Connect 必須要件、`strings.xml` に `health_connect_privacy_policy_url` を追加)
4. **なぜ事前に分からなかったか**: 子 2 着手前に `npm view @capgo/capacitor-health peerDependencies` で Capacitor 8 互換性は確認していたが、**同梱 AndroidManifest 内容までは確認しなかった**。README は「Privacy Policy 必須」と書いてあったが、permission 重複の話は source を読まないと判別できなかった

**教訓**: ライブラリ採用時の事前調査ステップに、以下を追加する:

```bash
# プラグインが Android で何を宣言しているか確認
grep -E "permission|activity" node_modules/<plugin>/android/src/main/AndroidManifest.xml

# permission の重複宣言が不要な場合が多い (= マニフェストマージ機構)
# 必須要件 (= Privacy Policy URL / queries / Activity 等) はソース or README で確認
```

**再現性**: この教訓は Strava / Stripe / OAuth 系プラグインでも再発しうる (= 「README ベースで作業 → ライブラリ同梱物に既にあった」事象)。次回ライブラリ採用時に同じ罠を回避できる粒度。

**良かった点**: 子 2 のスコープが「permission 3 種追加」から「Privacy Policy URL 設定」に変化したが、変化を「事前調査不足」ではなく「ライブラリ仕様の不確定性 = 着手で初めて判明する性質」として正直に記録できた (= strategic-reviewer の指摘通り、運の要素も含む)。

**残課題 (= 設計リスク)**: Privacy URL は本番固定 (`https://weight-dialy.onrender.com/privacy`) のため、**Render が落ちると Android アプリの Health Connect 連携が破綻** する依存関係が発生。発表会前リハ手順に「/privacy 疎通確認」を組み込むことで運用カバー、抜本対策 (= ローカル assets 化、ミラー化) は v1.1 で検討。

### 学び 13: Capacitor プラグイン × Importmap = グローバル参照で繋ぐ

Issue #40 子 3 (PR #133) で Stimulus controller から `@capgo/capacitor-health` プラグインを呼び出す方式選択を迫られた。Capacitor 公式は ES module import (= `import { Health } from '@capgo/capacitor-health'`) 標準だが、Rails 8.1 の Importmap (= CDN 直リンク、bundler なし) と組み合わせる慣習は確立されていない。

**3 案のトレードオフ**:

| 案 | 内容 | メリット | デメリット |
|---|---|---|---|
| A. Importmap で CDN pin | `pin "@capgo/capacitor-health", to: "https://cdn.jsdelivr.net/.../index.js"` | Rails Way 維持 | CDN 障害リスク、Capacitor の自動読み込みとの順序問題 |
| **B. window.Capacitor.Plugins.Health 経由** ⭐採用 | グローバル参照、import 不要 | Importmap 触らない、Capacitor 標準 inject 仕様に乗る | TS 型補完なし、動作未確認 (= 実機で確認必要) |
| C. esbuild / vite で bundle | Importmap 撤回、`app/assets/builds/` に出力 | Capacitor 公式推奨 | Rails 8.1 Importmap 慣習から外れる、教材性低下 |

**B 採用の決め手**:
- Capacitor は WebView に `window.Capacitor` を inject する仕様、プラグインも `Plugins.<name>` で global access 可能 (= 多くの Capacitor アプリで使われる方式)
- Rails 8.1 Importmap の慣習を維持 = Web 版に副作用ゼロ (= `feature/capacitor-init` ブランチでも Rails コードゼロ修正)
- 失敗時 (= プラグインが global に inject されない場合) のロールバックが軽い (= A or C に切替可能)

**実装パターン** (= Stimulus controller):
```javascript
// Capacitor 検知
isCapacitorNative() {
  const cap = window.Capacitor
  return typeof cap !== "undefined" &&
    typeof cap.isNativePlatform === "function" &&
    cap.isNativePlatform()
}

// プラグイン参照
healthPlugin() {
  return window.Capacitor?.Plugins?.Health
}

// Web 版での display: none、Capacitor 検知時のみ表示切替
connect() {
  if (!this.isCapacitorNative()) return
  this.element.style.display = ""
  // ... permission チェック等
}
```

**教訓**:
- **Capacitor プラグイン × Importmap = グローバル参照で繋ぐ** が Rails 8.1 構成の最適解
- Web 版への副作用ゼロを `display: none` 初期 + Capacitor 検知ガードで担保 (= spec で確認可能)
- TypeScript 型補完を諦めるトレードオフは許容範囲、教材性は dev-log で補強

**再現性**: 後続子 4 / 子 5a でも同じパターン (= `window.Capacitor.Plugins.Health` 経由) を継続。Capacitor + Rails Importmap の組み合わせを採用する後輩プロジェクトでも再利用可能な型。

### 学び 14: フィールド名の境界変換は MVP の急所 (= データ送信時の polish 全般)

Issue #40 子 5a (PR #137) で Webhook POST を実装する際、JS 側 (= Health Connect 由来) とサーバー側 (= Apple Shortcuts 互換) のフィールド名 / 型が異なる箇所を **Stimulus controller の payload 構築箇所 1 箇所に集約** する判断をした。

**境界変換の具体例 (= PR #137 sync メソッド)**:

| JS 側 (= Health Connect) | サーバー側 (= 既存 Webhook 互換) | 変換 |
|---|---|---|
| `floors_climbed` | `flights_climbed` | キー名変換 (= Apple Health vs Health Connect 歴史的差異) |
| `distance_meters: 4234.7` (Float) | `distance_meters: 4235` (Integer) | `Math.round(...)` (= サーバー側 `parse_numeric` が小数 Float reject) |
| `measured_on: "2026-05-05"` (JST) | `recorded_on: "2026-05-05"` (yyyy-MM-dd 厳格) | キー名変換 + JST 基準日付 (= 子 4 で `todayISODate()` 修正済) |

**設計原則**:
- **サーバー側を緩めない** (= 過去 API との互換性維持)。Apple Shortcuts と Capacitor アプリの両方が同じエンドポイントを叩く設計のため、サーバー側で「Float も受容」「キー名 alias」等の変更は他クライアント影響大
- **JS 側で吸収する** (= 新規ソースが既存に合わせる)。境界変換ポイントは Stimulus controller の `sync()` メソッド内 payload 構築 1 箇所、後輩がコードを追う際の発見コスト最小化
- **教訓**: API クライアントを後追いで増やすときは「既存 API ≒ 仕様」とみなし、新クライアント側で吸収する

### 学び 15: Capacitor SecureStorage を捨てて DOM 埋め込みにした判断記録

Issue #40 子 5a (PR #137) で Webhook の Bearer token を JS から参照する方法として、**Stimulus values 経由で Settings ページの HTML data 属性に埋め込む** 方式を採用 (= `data-native-health-webhook-token-value="<%= current_user.webhook_token %>"`)。当初の子 Issue 本文では「Capacitor Preferences / SecureStorage に保存」案だったが採用せず。

**判断の理由**:

1. **server.url モードでは WebView が同一オリジン + Cookie session 共有**: Capacitor アプリの WebView は `https://weight-dialy.onrender.com` を直接読み込み、ログイン Cookie で認証済み。Settings ページにアクセスすれば `current_user.webhook_token` がサーバー側で確定し、HTML 出力できる
2. **SecureStorage は「token を別途入力 → 永続化」フロー必須**: 初回 token コピー UI / 再生成時の入力やり直し / token 無効化検知 etc.、UX が複雑化
3. **既存 Apple Shortcuts セクションで token を既に表示済**: settings/show.html.erb の Step 2 で `current_user.webhook_token` を可視化、Capacitor 経由の DOM 埋め込みも同じセキュリティモデル (= ログイン必須、XSS 経由なら漏洩は同等)
4. **発表会までの時間制約**: SecureStorage 化 + 入力 UI で +1-2h、MVP 完成優先

**トレードオフ**:
- ❌ ログインしていない状態では token を取得できない → 開発者本人 dogfood 用途では問題なし
- ❌ Capacitor アプリで Web 版にログイン UI を経由する手間 → server.url で本番 Web を WebView 表示するため、ログイン UI もそのまま動作 (= 追加実装不要)
- ✅ Stimulus values API で型 / 名前空間が明確、後輩教材として綺麗

**教訓**: ネイティブストレージ (= SecureStorage / Keychain) を使うかは **「サーバー側で確定する値か」** と **「アプリ独自の永続化が必要か」** で判断。weight_dialy のように Web 版がメインで Cookie session が活きる構成では、サーバー埋め込みが最もシンプル。

### 学び 16: Capacitor + Android Studio + WSL2 の初回セットアップ沼 (= 環境構築系 5 ハマりポイント)

Issue #40 子 6 (実機 E2E) に着手した深夜、**コードゼロ行修正でも 2 時間以上溶ける** 環境構築の沼を踏破。後輩が同じ構成 (= WSL2 + Windows 側 Android Studio) で着手する際の地雷マップ。

**環境前提**:
- 開発: WSL2 (Ubuntu) 上で Rails / npm / git 一式
- Android Studio: Windows 10 側にインストール (= Linux 版を WSL2 内で動かすのは WSLg + HAXM 不整合で却下)

**沼 1: AEHD (Android Emulator Hypervisor Driver) のサービス起動失敗**
- エラー: `[SC] StartService はエラー 4294967201 により失敗しました` (= `0xFFFFFFA1` = `ERROR_VIRTUAL_MACHINE_NOT_RUNNING`)
- 原因: WSL2 が有効 = Hyper-V が動作中、AEHD と排他関係
- 対応: **無視で OK**。Hyper-V 環境では WHPX (Windows Hypervisor Platform) が代替として動く。Setup Wizard でエラー出ても `Finish` で進める

**沼 2: Japanese Language Pack が Marketplace に出ない**
- 原因: Android Studio 向け JLP は Google が独自分岐させており、Marketplace で公式配布されていない (= 2026 年 5 月時点の仕様、バグではない)
- 対応案 A: IntelliJ IDEA Community ZIP の `localization-ja` フォルダを Android Studio の `plugins/` にコピー (= 15-30 分、ビルド番号一致必須)
- 対応案 B: **英語のまま進める** (= 採用、時間優先)、操作は最小限なので英語で十分

**沼 3: WSL2 Write Permissions Issue**
- 症状: Android Studio で `\\wsl$\Ubuntu\...\android` を開こうとして「Write Permissions Issue: This project folder has restricted write permissions」表示
- 原因: WSL2 のファイルシステム (= ext4) を Windows 側プロセスからアクセスする際、9P プロトコルで権限が完全に伝わらない
- 対応: `/etc/wsl.conf` の `[automount]` 配下に `options = "metadata,umask=22,fmask=11"` を追加 + `wsl --shutdown`
  - **here-document の `EOF` インデントで内容が破壊された事例あり**: `printf '...' > file` 方式の方が確実
- それでも解決しない場合: **解決策 C = プロジェクトを Windows 側にコピー** (= `cp -r ~/workspace/.../android /mnt/c/dev/weight_dialy_android`)

**沼 4: Windows 側コピー時に node_modules 参照エラー**
- 症状: Android Studio で開いてビルドすると `Could not resolve project :capacitor-android` / `:capgo-capacitor-health`
- 原因: `android/capacitor.settings.gradle` が `../node_modules/@capacitor/android` を参照している。`android/` のみコピーしたので親ディレクトリに `node_modules/` が無い
- 対応: `node_modules` も Windows 側にコピー (= `cp -r ~/workspace/weight_dialy/node_modules /mnt/c/dev/`)
  - 結果: `C:\dev\node_modules` + `C:\dev\weight_dialy_android` で `../node_modules` が解決可能に

**沼 5: WSL2 シャットダウンで Claude Code セッションも落ちる**
- 症状: `wsl --shutdown` 実行で WSL2 全体が止まり、Claude Code も終了
- 対応: 再起動後に `claude` 再起動 + 文脈サマリーを最初のメッセージで貼り付けて即復帰
  - git log + dev-log + memory の **教材性インフラ** が状態復元の鍵 (= 学び 9 で確立した「環境制約は早めに表面化させる」原則の応用)

**教訓**:
- **環境構築は本番作業前 (= 別日 / 別セッション) に済ませるべき** (= 21:30 物理打ち止めを過ぎた深夜帯に Android Studio install から始まると、判断ミスが連鎖しやすい)
- **「WSL2 と Windows のファイルシステム境界」は不可逆な技術的選択** (= /home 配下 vs /mnt/c 配下 vs Windows 直下、それぞれ別の沼)
- **発表会のような時間制約環境では、初手で日本語化等の polish に手を出さない** (= 英語のまま進める方が確実)

### 学び 17: 実機で初めて発覚する 2 ブロッカー (= Rails 8 allow_browser × Capacitor + minSdk 不整合)

Issue #40 子 6 (実機 E2E) で Pixel 7 エミュレータでアプリ起動した瞬間に発覚した、**MVP の子 1-5a を main マージ後も実機未確認のまま残っていた制約**。PR #140 で fix。

**ブロッカー 1: Manifest merger 失敗 — minSdk 24 vs library 26**

\`\`\`
Manifest merger failed : uses-sdk:minSdkVersion 24 cannot be smaller than version 26
declared in library [:capgo-capacitor-health]
\`\`\`

- 原因: `@capgo/capacitor-health` 8.4.9 が **minSdk 26 (Android 8.0 Oreo+) を要求**、Capacitor デフォルトの minSdk 24 と不整合
- 対応: `android/variables.gradle` で `minSdkVersion = 24 → 26`
- **学び**: ライブラリ採用時に **README + 同梱 AndroidManifest だけでなく `build.gradle` の minSdk 要求も確認** (= 学び 12 の同梱物 grep の延長)

**ブロッカー 2: Rails 8 `allow_browser versions: :modern` が Capacitor WebView を弾く**

- 症状: アプリ起動 → 「Not Acceptable / Your browser is not supported」が真っ白画面に表示
- 原因: Capacitor の WebView UA は末尾に `wv` が付く Android System WebView 形式、Rails 8 の `:modern` 判定 (= Chrome 119+ / Firefox 121+ / Safari 17+ / Edge 119+) では弾かれる仕様
- 対応戦略の検討:

| 案 | 内容 | 採用 |
|---|---|---|
| A. allow_browser を削除 | Web 版にも影響、本来のセキュリティ機能を失う | ❌ |
| B. Header 認証で識別 | OAuth Cookie session と相性悪い | ❌ |
| **C. UA suffix + サーバー側 whitelist** | Capacitor 側で `appendUserAgent: "WeightDialyCapacitor"`、Rails 側で `if: -> { !ua.include?(...) }` で bypass | ⭐採用 |

- 採用案 C の実装:
  - `capacitor.config.json`: `android.appendUserAgent: "WeightDialyCapacitor"`
  - `application_controller.rb`: `allow_browser versions: :modern, if: -> { !request.user_agent.to_s.include?("WeightDialyCapacitor") }`
- **Rails 8 ソース確認**: `actionpack/lib/action_controller/metal/allow_browser.rb` で `before_action ..., **options` のように渡されているため、`if:` キーワードは正しく動く (= code-reviewer 確認済)
- 回帰防止 spec: `home_spec.rb` に Capacitor UA で 200 OK / 通常古いブラウザ UA で 406 Not Acceptable の対を追加

**教訓**:
- **「MVP 完成 = 実装上完成 ≠ 実機で動く」**: 子 1-5a を「MVP 達成」とラベルしたが、実機 E2E (子 6) で **2 ブロッカー** 発覚。MVP 判定は実機での 1 度の起動確認後にすべきだった
- **Rails 8 `allow_browser` × WebView 系プラットフォーム (Capacitor / React Native / Cordova) は必ず bypass 設計が必要**。Cookie session と独立したマーカー (= UA suffix) で whitelist が王道
- **UA suffix bypass はセキュリティ機能ではない**: UA spoofing で誰でも bypass 可能だが、`allow_browser` 自体が認証・認可ではなく「古いブラウザでの動作不全防止」目的のため許容範囲

**残課題 (= v1.1 polish 候補)**:
- 406-unsupported-browser.html の日本語化 (= design-reviewer 由来)
- Capacitor 経由ユーザーで `_banner_android` 非表示化 (= 現状は文言修正で代替、サーバー側 UA 判定で完全分岐は v1.1)

**子 6 着手後の追加発覚** (= 学び 17 の核心、N ブロッカーに拡張): 子 1-5a で「2 ブロッカー」と書いたが、実機で連鎖的に 4 ブロッカーに到達。子 6 (実機 E2E) 動作確認の 4 ラウンド fix:

| ラウンド | PR | ブロッカー | 解決策 |
|---|---|---|---|
| 1 | #140 | minSdk 24 vs library 26 (Manifest merger 失敗) + Rails 8 allow_browser × WebView UA | minSdk 26 + UA suffix bypass |
| 2 | #142 | Capacitor `appendUserAgent` 既知バグ #4886 #6037 (3 年放置) | `overrideUserAgent` workaround + `wv` 保険で二重防衛 |
| 3 | #146 | OAuth callback が Chrome Custom Tabs で開かれる (= Google "In-App Browsers Are Not Allowed" 2021 ポリシー) | `/auth/` パスを modern check スキップ |
| 4 | #147 | Custom Tabs から `/` に戻った時の Mobile Chrome UA で 406 | Mobile Chrome bypass で三重防衛 (応急対応) |

**「2 ブロッカー」表現は誤り**: 動作確認で**段階的に発覚する性質**のため、件数固定で記録すると後で嘘になる。記録フォーマットは可変件数前提で設計すべき (= strategic-reviewer 提案)。

### 学び 18: MVP 判定基準 — 機能完成 ≠ 動作確認完走 (= 子 6 動作確認の遡及反省)

子 1-5a を「Issue #40 B スコープ MVP 達成」と記録 (= PR #137 + 学び 14, 15) したが、子 6 (= 実機 E2E) で **4 度の追加 fix** (= PR #140 #142 #146 #147) が発覚。厳密には子 1-5a 完成時点では **MVP 未達**だった。

**MVP 定義の 2 段階化**:

| 段階 | 定義 | 検証方法 |
|---|---|---|
| **仮 MVP** | 機能実装完成、spec 全 pass | コードレビュー + CI green + spec |
| **本 MVP** | 実機 / エミュレータで動作確認完走 | E2E テスト + 動作確認スクショ |

**教訓**:
- **「機能完成 = 実装上完成」と「動作確認完走 = 実機完成」を区別する**
- MVP 判定は **本 MVP のみ** で行う、仮 MVP は途中状態として明示
- ハイブリッドアプリ / 組込み / IoT 等、E2E が絡む全プロジェクトに普遍的な原則
- Day 5 summary で「子 1-5a を MVP 終端」と書いた時点で実は不完全、子 6 完了後に MVP 判定すべきだった

### 学び 19: OAuth Custom Tabs と cookie storage の構造的問題 (= ハイブリッドアプリ + 外部認証の前提知識)

子 6 動作確認 4 ラウンド目 (PR #147) で発覚した **構造的問題**。Capacitor アプリと Chrome Custom Tabs は **別プロセス・別 cookie storage** で動作する。

**問題のフロー**:
```
Capacitor アプリで「Google でログイン」タップ
  ↓
Google "In-App Browsers Are Not Allowed" 2021 ポリシーで Capacitor WebView での OAuth 不可
  ↓
Android が Chrome Custom Tabs を強制起動 (= 別プロセス・別 cookie storage)
  ↓
Custom Tabs で OAuth 完了 → callback /auth/google_oauth2/callback
  ↓
Rails でセッション確立 → redirect_to root_path
  ↓
"/" を Custom Tabs 内で開く (= Capacitor アプリには戻らない)
  ↓
ユーザーが手動で Capacitor アプリに戻る → Capacitor アプリは未認証状態
```

**応急対応 (= PR #147 のスコープ)**: Custom Tabs 内ではホーム表示できる、ログインフローは「成立」する。
**根本解決 (= v1.0 で対応予定、Phase 2a/2b)**: Capacitor の **deep link / AppLinks 設定** で OAuth callback を Capacitor アプリに戻す + cookie 共有。

**v1.0 ロードマップ (= 約 2h、待ち最小)**:

| Phase | 内容 | 時間 | 待ち |
|---|---|---|---|
| 2a | `appUrlOpen` イベントで Custom Tabs から帰還 (= ダイアログ経由) | 1h | なし |
| 2b | AppLinks verify で seamless 化 (= ダイアログなし、自動アプリ起動) | 1h | 数十秒 (= AssetLinks fetch) |
| 2c | (発表会後) release 署名 + Play Store Internal Testing | – | 3 日 (= Play Console 登録) |

**教訓**:
- **ハイブリッドアプリ + 外部 OAuth は cookie storage 分離が前提**、deep link / AppLinks 設計が必須
- 「In-App Browsers Are Not Allowed」ポリシーは Apple / Google 共通の流れ、ハイブリッドアプリ設計時に最初から考慮
- 後輩教材として **「ハイブリッドアプリ × OAuth = deep link 必須」** をルール化、回避不能の前提知識として記録

### 学び 20: AssetLinks verify と Custom Tabs callback の構造的境界 (= Phase 2a/2b で発覚した根深い仮説)

学び 19 で予告した Phase 2a (PR #149) + Phase 2b (PR #151) を実装したが、**AVD 動作確認で deep link 機能せず** = 「アプリで開く?」ダイアログすら出ない。原因仮説を 6 つ立てた:

| 仮説 | 内容 | 解決策 |
|---|---|---|
| 1 | AssetLinks verify が端末側非同期処理で未完了 | 数分〜数時間待つ、または再起動 |
| 2 | AVD の Play Services 制約で verify 走らない | 実機テストで切り分け |
| 3 | Render の Content-Type / Cache-Control 不備 | `curl -I` でヘッダ確認 / Google AssetLinks Tester で検証 |
| 4 | APK 再 install のキャッシュ | Build > Clean Project + 完全アンインストール |
| 5 | **Custom Tabs 内 callback は AssetLinks 対象外** | Phase 3 (= `@capacitor/browser` plugin) で OAuth フロー全体を Capacitor 制御 |
| 6 | Google "In-App Browsers Are Not Allowed" 仕様で deep link が発動しない | 仮説 5 と同じ対応 |

**最有力仮説 (= 仮説 5/6)**:
- AssetLinks verify は **外部リンクのタップ時** (= 別アプリ、メール、SMS、URL バー直接入力) に発動する仕組み
- **Custom Tabs 内で開かれる URL は対象外** = OAuth callback は Custom Tabs プロセス内で完結する
- つまり Phase 2a/2b のアプローチは **OAuth Custom Tabs flow には効かない可能性**

**Phase 3 候補 (= Phase 2b で解決しない場合)**:
- **`@capacitor/browser` plugin** で OAuth フローを Capacitor 制御
  - `Browser.open()` で Custom Tabs を **明示的に起動 + 戻り制御**
  - callback URL を Capacitor アプリ側で intercept
- **Native OAuth plugin** (= `@capacitor-firebase/authentication` 等)
  - WebView を経由しない OAuth、native レイヤで token 取得

**動作確認の段取り (= 明朝)**:
1. AVD で再試行 (= 仮説 1、verify 反映待ち)
2. 実機で試行 (= 仮説 2、AVD 制約か確認)
3. `curl -I https://weight-dialy.onrender.com/.well-known/assetlinks.json` で Content-Type 確認 (= 仮説 3)
4. Google AssetLinks Tester で verify (= 仮説 4)
5. ダメなら **Phase 3 (= `@capacitor/browser`)** に切替

**教訓 (= 暫定、明朝確定予定)**:
- AssetLinks の標準的使い方 (= 外部リンクから自動アプリ起動) と **Custom Tabs 内 OAuth callback は別の問題ドメイン**
- 「deep link 設定すれば OAuth が seamless」は **間違った思い込み** (= 本日の判断ミス、明朝確定)
- 後輩教材として **「OAuth × Capacitor では `@capacitor/browser` または Native OAuth plugin が王道、deep link/AssetLinks は補助」** が正しい結論の可能性

---

## 🤝 ユーザー (= 本人) の判断ハイライト

1. **「next 案を切る」見送り判断**: 自分の提案を 3 者レビュー結果に基づき見送り、別 Issue 化。execution の冷静さ。
2. **「事前にレビューしてもらう」**: 実装前に 3 者レビューを走らせる判断、手戻り回避の聡明さ。
3. **「食べ物換算と AI の役割分担を整理」**: 画面構成上の重複懸念から AI 累計ベース化を別 Issue 化、設計判断の俯瞰力。
4. **「発表会フォーム提出のため Issue #39 close」**: 不要な Issue を即 close する潔さ。
5. **「メモリー化しましょう」継続**: Day 6 から続く教訓永続化習慣。
6. **「専用 email アドレス取得」**: プライバシーポリシー連絡先のために独自取得 (= weightdaily3@gmail.com)、実行力。
7. **「Issue #95 + #96 を片付ける」**: 時間リソースに余裕を見て polish 系を消化、長期視点でも judging 力。

---

## 📊 統計

- マージした PR: **27 本** (= #82, #87, #92, #97, #98, #100, #101, #102, #104, #107, #108, #110, #111, #113, #115, #117, #127, #130, #133, #136, #137, #140, #142, #146, #147, #149, #151)
- 起票した Issue: **31 件** (= 15 件 + Issue #40 子 Issue 8 件 #119-#126 + 派生 polish 8 件 #128 #131 #134 #138 #143 #144 #145 #150) + Issue #8 への追記 1 件
- close した Issue: **25 件** (= #39, #35, #58, #73, #75, #52, #84, #38, #71, #96, #95, #85, #86, #45, #72, #88, #89, #105, #106, #116, #119, #120, #121, #122, #123)
- 全体 spec: 348 → **431 examples** (= +83)
- 起票だけして実装はしないが残った polish Issue: **9 件** (= #83, #85-#86, #88-#91, #93-#94, #99)
- memory 永続化: **4 ファイル新規** (= project_day5_summary, feedback_irreversible_action_pr_pattern, feedback_random_with_seed_testability, feedback_dev_log_after_merge) + **MEMORY.md update**
- dev-log 整備: **5 ファイル新規** (= day-3 〜 day-7、PR #101 でマージ) + **運用ルール CLAUDE.md 化** (= PR #102)

---

## 🎯 残タスク (= ユーザー本人作業)

### 5/5 夜 (= 残時間)
- [ ] 本番動作確認 30 分 (= 退会フロー / 食品換算日替わり / プライバシーポリシー URL アクセス / AI 提案 / Webhook 受信)
- [ ] `max_count` 5 vs 7 の判断 (= 実物見て、必要なら微調整)

### 5/6 (= 発表会当日)
- [ ] 朝のヘルスチェック (= 本番が落ちてないか、AI が動いているか)
- [ ] 発表会フォーム提出 (= URL: https://weight-dialy.onrender.com/privacy / /terms / / 等)
- [ ] **発表会 19:00 締切**

### 発表会後 polish 候補 (= 9 件)
全件発表会後対応で OK。優先順は別途 board で管理。

---

## How to apply

- **次セッション (= 発表会後想定)**:
  - 本ドキュメントを最初に読む
  - 別 Issue 9 件から優先度に応じて 1 つずつ消化
  - v1.1 リリース計画 (= LINE 認証 / Capacitor Android / Strava 連携 等) との順序付け
- **AI 関連の不具合**: day-6.md の「AI 接続中の詰まり 4 件」を参照
- **新機能を追加する時の workflow**:
  1. 設計判断ポイントをユーザーと対話で詰める
  2. 大きい設計判断は **事前 3 者レビュー** (= Issue #71 で効果検証済み)
  3. rails-implementer 実装 → test-writer (= 明示依頼必要) → 3 者並列実装後レビュー
  4. レビュー指摘を修正 commit + 再レビュー → push → PR → CI 待ち → マージ
- **不可逆操作の実装**: feedback `feedback_irreversible_action_pr_pattern.md` 参照
- **ランダム性の実装**: feedback `feedback_random_with_seed_testability.md` 参照
