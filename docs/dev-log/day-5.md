# Day 5 開発ログ (2026-05-03 夜、5 時間 20 分の死闘)

GW 4 日目の夜セッション。Day 4 前半 (= ngrok 環境整備) の続きで、**iPad 実機 + Apple Shortcuts で `/webhooks/health_data` に 200 OK を返すところまで完成させる** ことが目標。結果として、目標は達成できた (= `Issue #35 完全達成`) が、その過程で **Authorization ヘッダキー末尾の不可視空白** という Apple Developer Forums の既知バグに 4 時間ハマった。**諦める前に web 検索したユーザー本人の判断** が、5 時間目に真因を引き当てた。後輩教材として「真因特定までの試行錯誤の物語」を全文記録する。

セッションテーマ: **「自分用 production 版」を超えて「配布可能 production 版」まで仕上げる**。具体: B 案 (= token ハードコード) → A 案 (= token を Import Questions 化) への昇格。

---

## 🎯 Day 5 の目標

1. iPad 実機で Apple Shortcuts を組んで `/webhooks/health_data` に POST → 200 OK 確認
2. WebhookDelivery の監査ログに 1+ success エントリが残る
3. **改変①**: `recorded_on` を「現在の日付」から動的取得 + `yyyy-MM-dd` 整形
4. **改変②**: `steps` を Health 実データ (= 「ヘルスサンプルを検索」アクション) から取得
5. **改変③**: token をハードコードから Shortcut の「入力を要求」(= Import Questions) で受け取るように変更 (= 配布版に昇格)
6. iCloud Shortcut として公開 + リンク取得 (= Issue #36 用)

---

## 🏆 達成事項

| 達成項目 | 結果 | 立証方法 |
|---|---|---|
| 環境再起動 (= devcontainer / ngrok / Rails) | ✅ | curl 200 OK |
| **B 案 Mac Shortcut 完成** | ✅ | クイックルックに `{"accepted":1}` |
| **iPad 実機で Shortcut 動作** | ✅ | WebhookDelivery 10+ success エントリ |
| **改変① recorded_on 動的化** | ✅ | payload に `"recorded_on":"2026-05-03"` |
| **改変② steps を Health 実データ化** | ✅ | payload に `"steps":12345` (= 実 Health 値) |
| **改変③ token を Import Questions 化** | ✅ | 入力を要求 → Bearer ピル → 200 OK |

### 最終構成 (= production 級 Shortcut)

```
[1] 現在の日付
[2] 入力を要求 (プロンプト: "weight_dialy の webhook_token を貼り付けてください")
    出力 Magic Variable 名: 「Bearer」 (※ iPadOS 26 が文脈で自動命名)
[3] ヘルスサンプルを検索 (歩数, グループ化=日, 制限=1)
[4] URL の内容を取得
    URL: https://<ngrok or 本番>/webhooks/health_data
    方法: POST
    ヘッダ:
      Authorization: Bearer + 「Bearer」ピル  ← 末尾空白厳禁!!
      Content-Type: application/json
      ngrok-skip-browser-warning: true (任意)
    本文 (JSON):
      records → 項目1 →
        recorded_on: 「日付」(現在の日付ピルにインライン書式 yyyy-MM-dd)
        steps: 「ヘルスサンプル」(検索結果直接挿入、詳細取得アクション不要)
        distance_meters: 800 (固定、将来 Health 連携)
        flights_climbed: 2 (固定、将来 Health 連携)
[5] (任意) クイックルック (URL の内容)
```

---

## 📜 タイムライン (時系列、5 時間 20 分)

### Phase 1: セッション開始 + 環境再起動 (18:30 - 19:30)

**目的**: 前セッション (= Day 4 前半) 終了状態から `Issue #35` 本体に着手。

実施:
1. memory 確認 (`project_day3_1_summary.md`, `project_apple_shortcuts_webhook_research.md`)
2. git 状態確認 (= main clean)
3. **Dev Container を VS Code から起動** (= WSL2 host から `docker` コマンド不可視のため)
4. **WSL2 host で `ngrok http 3000`** → URL: `https://unvaried-ideally-contour.ngrok-free.dev`
5. **container 内で `bin/rails s -b 0.0.0.0 -p 3000`** (= foreground)

**教訓**: WSL2 host と container は別シェル空間。**シェル分離問題** は今夜の伏線として何度も再登場。

### Phase 2: curl で 200 OK までの試行錯誤 (19:30 - 20:30)

「実機を組む前に経路確認」を curl で実施。**これが意外と長引いた**。

#### 試行 1: HTTP 401 (= シェル分離問題)

```bash
# WSL2 host で打った curl
$WH_TOKEN  # ← 空 (= export していなかった or container でしか export していない)
# → Authorization: Bearer (空)
# → 401 Unauthorized
```

**真因**: container 内で `bin/rails runner "puts User.first.webhook_token"` で取得しても、その値は WSL2 host に伝わらない。

**解決**: 手動コピペで WSL2 host のシェル自身で `export WH_TOKEN=...` 必要。

```bash
 export WH_TOKEN='ここに 24 文字'   # ← 先頭スペースで履歴除外
echo "len=${#WH_TOKEN}"            # → len=24 確認
```

#### 試行 2: 「token は 24 文字で正解」発見

- 私 (= Claude) の memory では `SecureRandom.hex(32)` (= 64 文字) と記載されていた
- 実装は `has_secure_token :webhook_token` (= 24 文字 base58)
- → **memory の skeleton が実装と乖離** していた (= api-researcher の起草段階の値)

#### 試行 3: payload schema 不一致発見

- memory の例: `{"steps":1234, "distance":..., "flights":...}` (= flat)
- 実装は: `{"records":[{"recorded_on":..., "distance_meters":..., "flights_climbed":...}]}` (= nested)
- → **memory が実装に追従していなかった**

#### 試行 4: 200 OK 達成

正しい schema + 正しい token で curl: **HTTP/2 200 + accepted:1**。

**教訓**:
- **memory > 実装ではなく、実装 > memory**
- memory は研究フェーズのスナップショットで、実装で進化した部分は劣化する
- → **「memory 参照 → 必ず実コードで verify」** を運用化

### Phase 3: Mac Shortcut で B 案 完成 (20:30 - 21:30)

**判断**: iPad より Mac で組む方が圧倒的に楽 (= Dictionary の入れ子操作)。Mac で組んで iCloud 同期で iPad に降ろす戦略。

#### 構築した B 案 Shortcut (= 4 アクション)

```
[1] テキスト: "Bearer <hardcoded token>"
[2] 辞書: records (配列) → 項目1 (辞書) → 4 フィールド
[3] URL の内容を取得 (POST + ヘッダ + 本文に辞書 Magic Variable)
[4] クイックルック (デバッグ)
```

#### Mac Shortcuts 固有の発見

- **「URL の内容を取得」の URL 欄は薄い `URL` プレースホルダー** (= 未入力時パラメータ名がそのまま表示)、タイトルの一部に見えてハマる
- 辞書アクションは Mac だと **ツリー状に全階層展開** されて見える (= iPad は画面遷移)
- Mac で動かないアクション: ヘルスケア系 (= HealthKit がない)、**編集は OK、実行は iPad 必須**

→ Mac で 200 OK + accepted:1 確認、iCloud 同期で iPad に Shortcut 配布。

### Phase 4: iPad 実機テスト (21:30 - 21:50)

iPad で ▶ 実行: **200 OK** ✅
- count = 4 → 6 → 8 → 10 (= 10+ runs successful)
- WebhookDelivery 監査ログに記録確認

ここまでは **順調**。本日の目標 1, 2 は達成。残るは改変①②③ (= 配布版への昇格)。

### Phase 5: 本番化 (= 改変①②③) — 真の山場 (21:50 - 23:30)

**戦略**: B 案 → A 案へ。3 つの改変が必要:
- ①: `recorded_on` を「現在の日付」から動的取得 + `yyyy-MM-dd` 整形
- ②: `steps` を Health 実データから取得
- ③: token をハードコードから「Import Questions」化

#### 改変①: `recorded_on` 動的化 (= 試行 3 回で解決)

##### 試行 1: 「日付を書式設定」アクション追加 → 形式が `2026/05/03 20:35`

- 期待 `2026-05-03` だったが想定外形式
- 原因: アクションの順序逆 (Format Date が URL action より下) → 未来参照で iOS が locale デフォルト文字列を使った

##### 試行 2: 順序修正後も同じ

- 原因: 「日付を書式設定」アクションを追加したつもりが「日付」アクション (= text → Date パーサー、別物) を追加していた
- 「日付を書式設定」と検索しても出てこない混乱

##### 試行 3 (= 最終解): インライン書式設定

- 当初提案 (= 別アクション必要) は誤り
- iPadOS 26 では **「現在の日付」ピルを直接タップ → 書式設定パネル → カスタム `yyyy-MM-dd`** で内部完結
- → `"recorded_on":"2026-05-03"` 出力確認

#### 改変②: `steps` Health 実データ化 (= 試行 3 回で解決)

##### 試行 1: 「項目から詳細を取得」アクションで「数量」抽出

- iPadOS 26 で「数量」選択肢がない
- → 「値」(= Value) に名称変更されていた発見

##### 試行 2: 「ヘルスケアサンプルの詳細を取得」アクション

- 「このバージョンの "ショートカット" ではこのアクションが見つかりませんでした」エラー
- → iPadOS 26 で機能しない / 廃止

##### 試行 3 (= 最終解): ヘルスサンプル変数を直接挿入

- `Find Health Samples` の `グループ化=日 + 制限=1` 出力を **そのまま steps 値欄に**
- → `"steps":12345` 出力確認 (= 手動 Health 投入値)

#### 改変③: token を Import Questions 化 — **大トラブル発生** (= 試行 9 回 / 4 時間)

##### 試行 1: 「毎回尋ねる」インライン Magic Variable

- Authorization 値欄に「Bearer + 毎回尋ねる」設定
- 実行 → **401 Unauthorized**

##### 試行 2: 「変数を設定」アクションを挟む

- iPadOS 26 で「変数を設定」の値欄が **文字列+変数の混在を受け付けない** らしいと判明

##### 試行 3: 「テキスト」アクション中継

- 「Bearer + 入力を要求の出力」を Text アクションで組み立てて、その出力を Authorization に挿入
- でも **「入力を要求」の出力 Magic Variable 名が分からない** (= Magic Variable ピッカーに出ない)

##### 試行 4: 「変数を選択」ピル経由

- ピッカーに「変数を選択」というメタなピルが見えるが、タップしてもポップアップが開かない (= iPadOS 26 の UI バグ?)

##### 試行 5: ユーザーの仮説 = 「使われている変数しか出ない」

- ピッカーの「変数を選択」は **すでに参照されている変数のみ表示** という仮説
- → **「入力を要求」の出力をどこかで一度参照すれば、他の場所のピッカーにも出る** はず
- 検証: 「入力を要求」の直下にクイックルックを追加 → 自動で「Bearer」変数が入った
- ★ **大発見**: **「入力を要求」の出力 Magic Variable 名は (なぜか) 「Bearer」と命名されていた** (= iPadOS 26 が前後の文脈から推測命名?)

##### 試行 6: ハードコード復帰 → ネットワーク切断 連発

- 試行 5 で構造が見えた → Authorization に「Bearer + 「Bearer」ピル」を組む
- 実行 → **「ネットワーク接続が切れました」**
- ハードコード `Bearer <token>` 直書きに戻しても → **同じくネットワーク切断**
- WebhookDelivery 確認: **直近 1 時間半リクエストが Rails に届いていない** (= iPad で送信前に破棄されている)

##### 試行 7: 環境再診断

- WSL2 host curl → 200 OK (= ngrok と Rails は健全)
- iPad Chrome で ngrok URL アクセス → 成功 (= iPad のネットワークも生きている)
- → **iPad の Shortcuts → ngrok 経路だけが死んでいる** という非対称
- ngrok 再起動 → URL 不変 (= ngrok-free.dev のドメインは sticky?)
- `ngrok-skip-browser-warning` ヘッダ追加 → ダメ

##### 一旦撤退議論 (= 3 者並列レビュー)

- strategic-reviewer: B 案推奨 (= 自分用 production 版で着地)
- design-reviewer: B 案推奨 (= 発表会では peer trial 不要)
- code-reviewer: B 案 + 翌日タスク 4 件指摘
- 私 (= Claude) の「明日 60 分」見積もりが **根拠なし** とユーザーから指摘 → 「解決策不明のまま延期は危険」

##### 試行 8 (= 真因突き止め) — Web 検索

ユーザーの「諦める前に web 検索」判断 → Apple Developer Forums で既知バグ発見:

> **「Get Contents of URL の空ヘッダ key-value ペア / ヘッダキーの末尾空白」が「ネットワーク接続が切れました」エラーの主原因**

→ ユーザーが Authorization の **キー名「Authorization」末尾に空白** を発見!!

##### 試行 9 (= 解決): 空白削除 → 200 OK

- Authorization のキー欄末尾の空白を削除
- iPad で ▶ → token 入力 → **HTTP/2 200 OK** ✅
- ハードコード → 変数版 (= Bearer + 「Bearer」ピル) に戻して再実行 → **同じく 200 OK** ✅
- 改変③ 完了!

---

## 🐛 真因まとめ (= 教材として最重要)

### iPadOS 26 Shortcuts の既知バグ

**ヘッダのキー名に末尾空白があると、iOS が RFC 違反として送信前にリクエストを破棄し「ネットワーク接続が切れました」を表示**

- 検出困難: UI 上は目視で空白が見えない
- 似たケース: 空のヘッダ key-value 行が残存しているとき
- POST リクエストでのみ発生する場合あり
- source: https://developer.apple.com/forums/thread/720728

→ **改変③ の 401 と「ネットワーク切断」が交互に出ていた理由**: ヘッダ編集を繰り返すうちに、ある時点で末尾空白が混入。それ以降は送信前に破棄され「ネットワーク切断」、空白がない時のみ Rails に到達して認証関連の 401 を返していた。

### 教訓

1. **Shortcuts でヘッダを編集したら、キー名の前後の空白を必ず確認**
2. 「ネットワーク接続が切れました」が出たら、まず WebhookDelivery を見て **実際にリクエストが Rails に到達しているか** で iOS 側 / サーバ側の切り分け
3. Apple 公式 Developer Forums は本当の既知バグ情報源 (= 最終手段で当たる価値あり)

---

## 🧠 iPadOS 26 Shortcuts UI 仕様 (= 今夜発見した変更点)

memory として将来役立つので集約:

| 旧 (= memory / api-researcher 想定) | 新 (= iPadOS 26 実物) |
|---|---|
| 「日付を書式設定」アクションを追加 | **「現在の日付」ピル をタップして直接書式設定** (= アクション不要) |
| 「項目から詳細を取得」 → 「数量」 | **「値」** (= Value) に名称変更 |
| 「ヘルスケアサンプルの詳細を取得」アクション必須 | **不要**、検索アクションの出力を直接 steps に挿入 |
| 「入力を要求」の出力名 = 「指定された入力」 | **「テキスト」** (= 入力タイプ名と同名) もしくは **「Bearer」** (= 文脈から自動命名) |
| Magic Variable ピッカー = 全変数表示 | **「すでに参照された変数」のみ表示** されることがある |
| 「変数を選択」ピル = ポップアップ展開 | **タップしても何も起きない** ことがある (= UI バグ?) |
| Authorization 値欄 = 文字列+変数の自由混在 OK | **キー名末尾空白に超敏感**、変数挿入後に空白が混入しやすい |

---

## 📝 memory 訂正項目

`project_apple_shortcuts_webhook_research.md` の skeleton に誤情報あり:

- ❌ `webhook_token = SecureRandom.hex(32)` (= 64 文字)
  → ✅ **`has_secure_token :webhook_token`** (= 24 文字 base58)

- ❌ Body schema: `{steps:..., distance:..., flights:...}` (= flat)
  → ✅ **`{"records":[{"recorded_on":..., "steps":..., "distance_meters":..., "flights_climbed":...}]}`** (= nested + キー名違う)

- ❌ Bearer prefix を必ず付ける
  → ✅ **Bearer prefix がなくても Rails の `delete_prefix` no-op で通る** (= ただし iOS が送信前に弾くので付けるべき)

→ 余裕あるとき api-researcher 用 memory を実装後の真値に更新する。

---

## 🚨 code-reviewer 指摘 (= 翌日以降の Rails 側修正タスク)

| 優先度 | 内容 | 工数目安 | ファイル |
|---|---|---|---|
| 🚨 1 | `recorded_on` を `Date.strptime("%Y-%m-%d")` 厳格パース化 (= 現状 silent 丸めで「同日 2 回送信で 422」のバグ温床) | 30 分 | webhooks_controller.rb |
| ⚠️ 2 | `upsert_records` に数値型ガード追加 (= Health Sample object が steps=0 で silent 保存されうる) | 20 分 | webhooks_controller.rb |
| ⚠️ 3 | `record_delivery!` に accepted カウント記録 (= steps=0 が success ログに埋もれる) | 15 分 | webhooks_controller.rb |
| 💡 4 | Shortcut 側に `If Count > 0 then POST` ガード | 改変ついで | iPad Shortcut |

---

## 🎯 戦略的気付き (= 今夜のセッションから抽出)

### 1. 「明日に持ち越し」は解決策が明確な時のみ

- 解決策不明のまま延期 = **明日も同じ穴に落ちる**
- 今夜の撤退議論で「明日 60 分」を提案したが **根拠なし** → ユーザー指摘で却下
- 正解: タイムボックス + 全滅時のフォールバック (= 突破口 1〜3 を順に試行 + ダメなら C 案コミット)

### 2. 「諦める前に web 検索」の威力

- 4h ハマっても解けなかった問題が、5 min の web 検索で原因特定
- Apple Developer Forums の既知バグ情報は **机上検討では絶対に思いつかない**
- → 「行き詰まったら web 検索」は重要な思考切替トリガー

### 3. 体力管理 vs 進捗欲

- 22:30 過ぎから 1.5 時間追加で粘って正解だった (= 真因特定 + 改変③ 完了)
- ただし「諦めずに粘れ」が常に正解ではない
- 今夜の判断材料: **撤退条件 (= 23:30 までに突破口 3 全滅なら撤退)** を明確にしたうえで粘る、という構造がよかった

### 4. 3 者並列レビューの限界

- strategic / design / code の 3 者全員 B 案推奨だった
- でも **3 者とも机上検討の範囲** で、web 検索による既知バグ情報は知らなかった
- → 3 者並列レビューは「意思決定の枠組み」を整理する役、**真因特定は別の手段** が必要

### 5. memory > 実装 ではなく 実装 > memory

- 今夜判明した memory との乖離 (= token 文字数 / payload schema)
- → memory は研究フェーズのスナップショット、実装で進化した部分は劣化
- 運用ルール: **memory 参照 → 必ず実コードで verify**

---

## 🤝 ユーザー (= 本人) の判断ハイライト

今夜のセッションでユーザー本人が下した重要判断:

1. **「お風呂入る前に段取り確認」**: 中断前に再開可能な状態で残す習慣
2. **「明日に回しても 30 分で終わるはずがない」**: 私 (= Claude) の楽観的見積もりへの的確な指摘
3. **「解決策不明で延期は危険」**: 撤退条件のない先延ばしの危うさを言語化
4. **「諦める前に web 検索」**: 真因特定への決定打
5. **「Authorization の後ろに空白がある」発見**: 5 時間の混沌を終わらせた目視確認

→ **教材として、ユーザーの判断パターンも価値が高い**。後輩にこの dev-log を渡すとき「主担当 (= Claude) の提案を全部受け入れず、批判的に判断する」姿勢のモデルケースとして使える。

---

## 📦 セキュリティ inc.

- **token 共有の判断**: ユーザーが「token 貼っていい?」と確認 → 貼らせない判断
- **token 環境変数化** (`export WH_TOKEN=...`): 履歴除外 (= ` ` 先頭スペース) で安全運用
- **token Gyazo 流出**: 1 度発生、即再生成で対処、Gyazo スクショ削除は Task として未消化
- **Shortcut 内 token ハードコード**: 自分用 production 版では OK、配布版は Import Questions で個別化必須

---

## 📊 セッション統計

- セッション時間: **5 時間 20 分** (18:30 - 23:50 JST)
- 主要トラブル: 3 件 (= シェル分離 / iPadOS 26 UI 変更 / Authorization 末尾空白)
- 試行錯誤回数 (= 改変③だけで): **9 回**
- 真因特定までの時間: 約 **4 時間** (= 21:30 改変③着手 → 23:30 真因特定)
- WebhookDelivery 件数の変遷: 1 → 4 → 10 → 14 (= 推定、最終時点)
- 学んだ iPadOS 26 仕様変更: **7 件**
- 教材化された判断ハイライト: 5 件

---

## How to apply

- **Day 6 (= 翌日 5/4 朝)**:
  - iCloud Shortcut 公開 + リンク取得 (= Issue #36 用、5 分)
  - code-reviewer の 🚨 1 反映 (= `recorded_on` 厳格パース化、30 分 + テスト)
  - **本番デプロイ着手** (Render or Kamal、半日)
- **「ネットワーク接続が切れました」が出たら**: ヘッダの空白チェックを最優先
- **iPadOS Shortcuts UI で迷ったら**: 上記の「iPadOS 26 仕様」表を参照
- **memory に書いてある skeleton と実装が違う**: 実装側を真とする運用、余裕あるときに memory 訂正
- **行き詰まったら**: 5 分 web 検索 → 既知バグ確認
