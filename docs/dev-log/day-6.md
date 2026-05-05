# Day 6 開発ログ (2026-05-04、Render 本番デプロイ + AI 接続)

GW 5 日目。Day 5 (= 5/3 夜) の 5h 死闘で **iPad 実機 → Webhook 200 OK** を達成した翌日、本日は **本番公開 + 本物の AI 接続** という 2 大マイルストーンを 1 日で達成する。朝〜昼に Render Free Tier への初回デプロイで 4 連続のエラーを踏み抜き、午後〜夕方に Anthropic Claude Haiku 4.5 接続で再び 4 連続のエラー。**1 日で 15 PR マージ + 8 個のトラブル踏破** という、本プロジェクト最大ボリュームのセッション。

セッションの戦略テーマ: **「Day 5 残タスクの巻き取り + Render 本番デプロイ完遂 (午前) + MVP 後機能を発表会前に前倒し (午後)」**

---

## 🎯 Day 6 の目標

### 午前 (= デプロイフェーズ)
1. Day 5 残タスク 4 件の巻き取り (= iCloud Shortcut リンク差込 / sketch-btn 44px / recorded_on 厳格パース / WebhookDelivery 履歴表示)
2. **Render Free Tier への本番デプロイ完遂**
3. GAS warmup の仕込み (= cold start 対策)
4. iPad Shortcut の URL を本番 URL に切替

### 午後 (= MVP 後機能フェーズ、攻めの判断)
1. 「貯カロリー」(= カロリー貯金システム v1.0) を発表会前に投入
2. AI 提案カードを **本物の Anthropic Claude API** で動かす
3. ハマり踏破時の hotfix で連鎖デプロイをこなす

---

## 🏆 達成したこと (= 計 18 PR + 5 Issue close + 11 Issue 起票)

### マージ済み PR (= 朝 9 本 + 午後 6 本 + 夕方 3 本 = **18 本**)

| 時間帯 | PR | Issue | 内容 |
|---|---|---|---|
| 朝 | #46 | #36 | Settings Step 3 に iCloud Shortcut リンク差込 |
| 朝 | #50 | #47 | sketch-btn 44px タップ領域 (= WCAG 2.5.5 / Apple HIG 準拠) |
| 朝 | #54 | #51 | recorded_on 厳格パース化 (= Date.strptime + 正規表現の二段構え + InvalidPayload 例外) |
| 朝 | #59 | #53 | Settings に WebhookDelivery 送信ログ表示 (= 直近 5 件) |
| 朝 | #60 | #57 | `config.time_zone = "Tokyo"` + JST 表記統一 |
| 朝 | #62 | #37 | **Render Free Tier 本番デプロイ環境構築** (= render.yaml + bin/render-build.sh + database.yml A 案 + production.rb SSL/host 設定 + README §11) |
| 朝 | #63 | – | production-specific credentials (= Google OAuth client_id/secret) |
| 朝 | #64 | – | hotfix: render-build.sh で `npm install` 実行 (= daisyUI 解決) |
| 朝 | #65 | – | hotfix: A 案同居で Solid Trifecta 各 schema を primary DB に明示 load |
| 昼 | #68 | #67 | iCloud Shortcut URL 更新 (= Settings 画面の banner リンク差し替え) |
| 昼 | #69 | #48 指摘 4 | HealthKit 権限案内追加 |
| 午後 | #74 | #41 | **「貯カロリー」(= カロリー貯金システム v1.0)** (= 月リセット + 累計二段構造、強要表現禁止、「貯カロリー」直球造語採用) |
| 午後 | #76 | #42 | **CalorieAdviceService を Anthropic Claude Haiku 4.5 で AI 化** (= tool_use で JSON 厳密強制 + ai_available? + フォールバック) |
| 午後 | #77 | – | anthropic.api_key を production credentials に投入 |
| 午後 | #78 | – | hotfix: yaml `:` 後スペース欠けで String 化される (= credentials nested 構造化) |
| 夕方 | #79 | – | rails-i18n 導入 + デフォルトロケール `:ja` 固定 (= 国内向けに堅牢化) |
| 夕方 | #80 | #48 #58 #75 | Settings/dashboard polish 4 件まとめ (= 本番 URL font-size / AI バッジ / 最終送信 N 分前 / Step 3 動的表示) |
| 夕方 | #81 | #70 #73 | CalorieSavingsService を `class << self` 構成に統一 + 月初ゼロ励ましコピー追加 |

### close した Issue
- #36 #47 #51 #53 #57 (= PR マージで自動 close)
- #37 (= Render デプロイ完遂)
- #41 #42 (= MVP 後機能本命 2 件、v2.0 リリース予定だったものを発表会前に前倒し完了)
- #61 GAS warmup (= 10 分間隔 trigger 設定完了)
- #66 本番デプロイ後の動作確認チェックリスト

### 起票した Issue (= 11 件、5/5 以降の検討材料)
- #48 (= 拡張) Settings 画面まるごと polish 集
- #49 navbar 高さ膨張対応
- #52 webhooks_controller 数値型ガード + accepted カウント
- #55 user preferences (= unauthorized 表示オン/オフ)
- #56 ViewComponent 導入検討
- #58 「最終送信: N 分前」セクション冒頭表示
- #70 月初ゼロ励ましコピー (= polish 系)
- #71 食べ物換算「アイス何個分?」(= feature 拡張)
- #72 home_controller の SQL 集計化 (= perf 改善、長期運用時)
- #73 service refactor (= class << self + i18n delimiter 明示)
- #75 「Powered by Claude」バッジ (= 発表会向け教材性向上)

---

## 🐛 デプロイ中 4 連発の詰まり (= 朝〜昼の死闘)

Render Free Tier への初回デプロイで連続 4 個のエラーを踏み抜いた。

### 詰まり 1: `RAILS_MASTER_KEY` 末尾 1 文字欠け

**症状**: `MessageEncryptor::InvalidMessage` で credentials 復号失敗、ビルド時に `omniauth.rb` 初期化で起動エラー。

**真因**: Render Dashboard の「Specified configurations」入力欄に `cat config/credentials/production.key` の値を貼った時、**末尾 1 文字が欠けていた** (= コピペ事故)。

**判別方法**:
```bash
cat config/credentials/production.key | wc -c
# → 32 (= 改行なし) or 33 (= 改行あり)
# Render の RAILS_MASTER_KEY が 32 文字 hex と完全一致するかを目視確認
```

**対処**: Render の Environment タブで `RAILS_MASTER_KEY` を完全クリア → 正確に貼り直し → Save → 自動再デプロイ。

**教訓**:
- Render の Environment 入力欄は **末尾改行に厳しい**
- ターミナル出力の値を貼る時は **末尾改行を含めずダブルクリック選択** が安全
- `production.key` を別途控えた時点で `wc -c` チェックを習慣化

### 詰まり 2: daisyUI が `node_modules` に居ない (= `npm install` 抜け)

**症状**: `Error: Can't resolve 'daisyui' in '/opt/render/project/src/app/assets/tailwind'` で `tailwindcss:build` (= `assets:precompile`) が落ちる。

**真因**:
- `package.json` で daisyUI を devDependencies に持っている (= npm package)
- `app/assets/tailwind/application.css` で `@plugin "daisyui";` 参照
- Render の Ruby buildpack は **Node.js を同梱するが `npm install` を自動実行しない**
- 結果として `node_modules/daisyui` が空 → Tailwind ビルド失敗

**対処**: `bin/render-build.sh` に `npm install` を追加 (= `bundle install` と `assets:precompile` の間)。

**教訓**:
- Rails + Tailwind 4 + daisyUI 構成では Render で **必ず `npm install` 明示** が必要
- `package.json` がある = `node_modules` に依存している、と早めに気付く
- `package.json` を覗いて devDependencies を確認するのが最初のチェック

### 詰まり 3: A 案 Solid Trifecta 同居の `db:prepare` 罠 (= 最大の山)

**症状**: ビルド成功 + Puma 起動成功 (`Listening on http://0.0.0.0:10000`) だが、起動直後に `PG::UndefinedTable: relation "solid_queue_recurring_tasks" does not exist` で Solid Queue supervisor がクラッシュ → Puma 再起動ループ → 502 Bad Gateway。

**真因**:
- `database.yml` の production セクションで cache/queue/cable がすべて同じ `DATABASE_URL` を参照 (= A 案同居)
- `db:prepare` は **「同じ DATABASE_URL は処理済み」と判定して cache/queue/cable の `_schema.rb` を load しない** (= Rails multi-db の仕様)
- 結果として `solid_queue_*` `solid_cache_entries` `solid_cable_messages` テーブルが作られない
- Solid Queue supervisor は起動時に `solid_queue_recurring_tasks` を読みに行く → テーブル無い → クラッシュ → Puma 全体が「Solid Queue が gone away」と判定 → shutdown → Render が再起動 → 無限ループ

**対処**: `bin/render-build.sh` で各 `_schema.rb` を primary DB に明示 load (= marker テーブル存在チェックで冪等性確保)。

```ruby
bundle exec rails runner '
  marker_tables = { cache: "solid_cache_entries", queue: "solid_queue_jobs", cable: "solid_cable_messages" }
  marker_tables.each do |db_name, marker|
    if ActiveRecord::Base.connection.table_exists?(marker)
      puts "[#{db_name}] schema already loaded, skipping"
    else
      schema_file = Rails.root.join("db/#{db_name}_schema.rb")
      if schema_file.exist?
        load schema_file
        puts "[#{db_name}] loaded #{schema_file.basename}"
      end
    end
  end
'
```

**将来の撤退ポイント**: 有料プラン化で cache/queue/cable を別 DB 化したら、この明示 load ブロックは削除可能 → `db:prepare` だけで完結する Rails 標準構成に戻る。

**教訓**:
- Solid Trifecta + 1 DB 同居は **Rails 公式推奨ではないが、Free Tier では現実解**
- `db:prepare` の挙動は「database 名」ベースではなく「DATABASE_URL」ベースで判定される (= 同一 URL は重複処理しない)
- 502 Bad Gateway = Render proxy → Rails 通信失敗、原因は ① bind 0.0.0.0 / ② health check 経路 / ③ **Rails 起動失敗で再起動ループ** の 3 通り、③ の場合 Logs にエラーが流れる

### 詰まり 4: 本番 DB と development DB は完全別物 (= token 再生成事件)

**症状**: 本番に Shortcut 送信 → 401 Unauthorized。

**真因**:
- 本番 DB (= Render Postgres) は **真新しい空っぽの DB**、development DB とは別物
- 本番で初めて Google ログインした瞬間に **新しい User レコード** が作られる → 新しい `webhook_token` が `has_secure_token` で発行される
- ユーザーは development 時の token を iPad に貼っていた → 本番 DB には存在しない token → 401

**対処**: Settings 画面で本番の token を確認 → iPad の Shortcut 入力プロンプトでそれを貼り直し。

**教訓**:
- Rails アプリでは「DB が変われば全データが別物」(= 初学者が踏みやすい盲点)
- 「本番デプロイ後に Shortcut が動かない」ときは、まず Settings の token と iPad の token が一致しているか確認
- 「再起動でトークンが再生成される」は誤解、正しくは **「本番初回ログインで新規 User として扱われた」**

---

## 🐛 AI 接続中の詰まり 4 件 (= 午後の死闘、教材性最大の章)

朝のデプロイを乗り越えた後、午後は **MVP 後機能の AI 接続** に着手。Anthropic Claude Haiku 4.5 を `CalorieAdviceService` に組み込む過程で、また 4 連続のトラブル。

### 詰まり 1: WebMock + Anthropic Ruby SDK 1.36 の互換性問題

**症状**: spec で `client.messages.create(...)` を WebMock で stub_request → request body 構築段階で `NoMethodError: undefined method '[]' for an instance of StringIO`。

**真因**: 不明 (= SDK の Net::HTTP layer 内で response body の StringIO 処理に WebMock が干渉)。

**対処**: WebMock を諦め、SDK のメソッド単位 stub に切り替え:

```ruby
allow(Anthropic::Client).to receive(:new).and_return(client_double)
allow(client_double).to receive(:messages).and_return(messages_resource)
allow(messages_resource).to receive(:create).and_return(mock_response)
```

**教訓**:
- 外部 API SDK の spec は「内部の Net::HTTP まで stub」より「**SDK のメソッド単位 stub**」の方がシンプル + SDK upgrade 耐性
- WebMock は「素朴な API クライアント」用、SDK が独自 transport 持つと相性悪い
- `WebMock.disable_net_connect!` を `rails_helper` で global にすると他 spec を巻き込むので、必要な spec の `before` で局所化する運用が筋

### 詰まり 2: YAML の `:` 後スペース欠けで String 化

**症状**: 本番デプロイ後、`[CalorieAdviceService] AI failed (TypeError: String does not have #dig method)` で AI が呼べず Static フォールバック発火。

**真因**: ユーザーが production credentials に追加した時、`anthropic:sk-ant-api03-xxx` (= `:` 直後スペース無し) と書いてしまった。YAML parser が `anthropic` キーの値を **String として解釈**、`Rails.application.credentials.dig(:anthropic, :api_key)` で `String#dig` が呼ばれて `TypeError`。

**対処**:
```yaml
# Before (= NG)
anthropic:sk-ant-api03-xxxxxxxx

# After (= OK)
anthropic:
  api_key: sk-ant-api03-xxxxxxxx
```

**教訓**:
- YAML の `key: value` は **`:` の直後にスペース必須** (= `key:value` だと parse 結果が変わる)
- credentials 編集時は **必ず nested 構造にして 2 行以上で書く** (= `:` 1 行で詰めない)
- `TypeError on String` → ほぼ Hash 期待箇所で String が来ているサイン、credentials yaml を最初に疑う

### 詰まり 3: Prompt caching の最低 token 数 4096 に届かない silent 無効

**症状**: `cache_control: { type: "ephemeral" }` を SYSTEM_PROMPT に設定したが、Haiku 4.5 では cache 効果ゼロ、コスト試算が誤読される。

**真因**: Anthropic models の cache 最低 token 数が分かれている:
- Sonnet 4.5/4.6 = 1024 token
- Sonnet 3.7/Haiku 3 = 2048 token
- **Haiku 4.5 / Opus 系 = 4096 token**

現状の `SYSTEM_PROMPT` は ~2000 token で 4096 に届かず → silent 無効。

**対処**: PR #76 で `cache_control` を **意図的に外した** + コメントに「将来 SYSTEM_PROMPT を膨らませた時に追加」と記録。

**教訓**:
- Prompt caching は **model 別の最低 token 数を必ず確認**
- 「効いてるはず」を検証するには `usage.cache_creation_input_tokens` と `usage.cache_read_input_tokens` を見る (= 0 のままなら silent 無効)
- 中途半端に設定するとコスト試算が狂うので、**効かないなら外す方が筋**

### 詰まり 4: Anthropic Ruby SDK の `system_:` 命名

**症状**: `client.messages.create(system: "...", ...)` で実装したが SDK が受け取らない。

**真因**: Anthropic Ruby SDK 1.36 では Ruby の `Kernel#system` 衝突回避で **`system_:`** (= 末尾アンダースコア) と命名されている。

**対処**:
```ruby
client.messages.create(
  system_: SYSTEM_PROMPT,  # ← 末尾 _ 必須
  ...
)
```

**教訓**:
- 各言語 SDK の予約語回避命名は確認必須 (= JS なら `system`、Python なら `system`、Ruby だけ `system_`)
- SDK のメソッド signature を `instance_method.parameters` で必ず確認

---

## 🧠 副次的な気付き

### `ai_available?` パターン (= 教材性高)

```ruby
def self.ai_available?
  Rails.application.credentials.dig(:anthropic, :api_key).present?
end
private_class_method :ai_available?
```

- credentials 未設定環境 (= test/development) では AI を skip → 自動的に Static にフォールバック
- production credentials 投入後に AI が有効化される
- これにより:
  - test で WebMock 不要
  - dev での偶発的な API 課金を防止
  - production 切替が credentials 投入だけで完結

→ **外部 API 連携の Rails 実装パターンとして再利用可能**。

### 「貯カロリー」ブランド造語の判断

PR #74 (= Issue #41 = カロリー貯金) でユーザーが採用した命名:
- 「貯金: 1,234 円」(= 疑似通貨化) より
- **「貯カロリー: 1,234 kcal」** (= 直球造語) を選択

**理由**: 比喩を解さなくても伝わる + ブランド独自性 + アプリ哲学 (= 罪悪感能動的反転) と完全一致。

詳細: memory `project_weight_dialy_three_step_philosophy.md` の「コピーライティング判断」セクション。

### 「強要しない」原則 (= Issue #41 で確立、Issue #42 でも継承)

- 矢印 (= ↑↓) / 色分け (= 赤緑) / 前月比計算なし → 並列表示のみ
- AI プロンプトにも「目標達成」「がんばって」等の **強要表現禁止** を明示
- 「ユーザーに『どう解釈するか』を委ねる」が weight_dialy の核

### Render の Specified configurations 画面の挙動

- Blueprint Apply 前に表示される設定プレビュー画面
- `sync: false` (= render.yaml で書いた) の項目は **入力欄として表示される or "Set in Dashboard" と表示される** (= Render UI バージョン依存)
- 入力欄が出てきたら **`RAILS_MASTER_KEY` は先に貼っちゃう** = 初回ビルド成功確率が上がる
- `APP_HOST` は Web Service 作成後に Render が割り当てるドメインを使うので、**仮値 `weight-dialy.onrender.com` を入れて後で正確な値に書き換え** が筋

### GAS warmup の仕込み

- https://script.google.com で「新しいプロジェクト」
- `pingRender()` 関数 (= `UrlFetchApp.fetch` + エラー時 `MailApp` 通知)
- 時間ベース trigger で 10 分間隔
- 初回手動実行時に権限承認 (= UrlFetchApp + MailApp)
- 動作確認: Render Logs に `GET /` が 10 分間隔で来る

→ **Free Tier の cold start 対策**として、コスト 0 で運用継続できる構造。

---

## 🎯 戦略的気付き

### 1. デプロイ詰まりは 4 連発が現実

- ローカルで完璧に動いていても、本番デプロイで 4 個詰まるのが普通
- 「1 つ解決すると次が出てくる」を覚悟して計画を立てる
- 各詰まりは 5 分〜30 分で解決可能なので、トータル 1-2 時間の余裕を見ておく

### 2. ログを読む力 = デプロイの 9 割

- 「502」を見て「Listening があるから OK」と判断したのは間違いだった
- 必ず **Logs の末尾エラーを最初に確認** する
- スタックトレースを下から読む (= 最深部にエラー本体)

### 3. hotfix PR の躊躇いは禁物

- 完璧な PR を待たず、詰まったら即 hotfix PR で前に進む
- Day 6 では 7 機能 PR + 2 hotfix PR + 6 PR (= 午後分) + 3 PR (= 夕方 polish) = **18 PR を 1 セッションで捌けた**
- hotfix PR も 3 者並列レビューを通すのは過剰、軽微変更は WHY コメントで補強して直接マージで OK

### 4. 「攻め」判断が刺さった (= MVP 後機能の前倒し)

- 朝のデプロイ完遂で「ここまでで発表会 OK」の選択肢があったが、ユーザーが「**MVP 後機能を前倒しで**」を選択
- 結果: 本物の AI が production で動く weight_dialy に進化、発表会のアピール度大幅向上
- **教訓**: 締切に余裕がある時の「攻め」判断は、本番で検証する時間があるかで判断する

### 5. 「fail-fast + フォールバック」設計の威力

- AI 接続で 4 詰まり (= 全部 production で踏んだ) があったが、すべて **Static フォールバックで UX は崩れず**
- Render Logs で `[CalorieAdviceService] AI failed (...)` ログから即座に原因特定 → 1 PR で解決
- **教訓**: 外部依存は「失敗を前提に設計」、ログで失敗を観測可能にする

### 6. memory 駆動開発の効果

- アプリ哲学を memory 化したのが Day 6 朝、午後の Issue #41/#42 設計判断で何度も参照
- 「強要しない」「3 ステップ思想」「貯カロリー命名」が **判断軸として機能**
- **教訓**: 設計議論で出た哲学は memory に永続化、後の判断で blunt な議論を避けられる

### 7. memory ベースの教訓化 = 後輩への最大の贈り物

- デプロイ詰まり 4 件 + AI 接続詰まり 4 件 = **8 件の「初学者が必ず踏むトラップ」**
- 1 つ 1 つ memory に永続化すれば、次の人 (= 後輩 / 未来の自分) は数時間〜半日節約できる

---

## 📊 セッション統計

- セッション時間: 約 8-9 時間 (= 7:00 - 15:30 推定)
- 主要トラブル: **8 件** (= デプロイ 4 + AI 接続 4)
- マージした PR: **18 本** (= 1 日記録、本プロジェクト最大ボリューム)
- close した Issue: **5 件**
- 起票した Issue: **11 件** (= polish 系 + future 機能 + 本動作確認チェックリスト)
- 設計議論を経た判断: A 案 (= Solid Trifecta 同居) / B 案 (= environment-specific credentials) / Render 採用根拠 4 点 / Step 3 動的表示の 3 案 / 「貯カロリー」直球造語

---

## 🤝 ユーザー (= 本人) の判断ハイライト

今日のセッションで本人が下した重要判断:

1. **「render の対策としては gas を使って定期的にアクセスは知らせましょう」**: cold start 対策の正解を即座に提案、コスト 0 で運用継続できる構造
2. **「ハイブリッド構成 (= 鍵別 / OAuth client 共用)」を選択**: MVP の妥協として合理的、将来分離パスを残す
3. **「A 案で作業はやっちゃってください」**: 教材的解説を読んで判断、設計判断を技術解説で確認するスタイル
4. **「再起動時にトークンが再生成されるのを知らずに古いものをやっていました。トラブルシューティングとして後で資料化お願いします」**: 詰まったら必ず教訓化を依頼するスタンス、これが教材性に直結
5. **「Issue 化からやりましょう」**: 散らかさない運用、tracking Issue として残す習慣
6. **「Aで行きましょう (= 締切リスク取って攻める)」**: AI を発表会前に本番投入する判断
7. **「貯カロリー直球で」**: 比喩より直球造語を選ぶブランド判断
8. **「数値プレッシャー強要しない」**: 矢印・色分け・前月比禁止の哲学確立
9. **「3 ステップ思想は機能取捨の北極星」**: アプリ全体の判断軸を言語化
10. **「memory 化しましょう」即決**: 教訓化を後回しにしない習慣

→ 本人の「**実行力 + 機転 + 体力管理 + 教訓化**」が weight_dialy 開発を支えている、という構造。

---

## 📦 セキュリティ inc.

- **Anthropic API key の取り扱い**: production credentials のみ、ローカルでも `.env` ではなく credentials 推奨
- **API key 漏洩対策**: `production.key` は git ignore 済み、Render 環境変数経由で注入
- **AI プロンプトの値**: kcal の整数のみを送信、user 個人情報は含めず

---

## How to apply

- **Day 7 (= 翌日 5/5、発表会前日)**:
  - 残タスク優先度確認 (= polish 系 #48 #58 #75 / 発表会デモ準備 #39 / 数値ガード #52)
  - 5/6 朝までに撤退判断
- **AI 関連の不具合に遭遇したら**:
  - まず Render Logs の `[CalorieAdviceService]` を grep
  - `AI failed (TypeError: String does not have #dig method)` → yaml の `:` 後スペース疑う
  - `AI failed (Anthropic::AuthenticationError)` → API key 値ミス疑う
  - `AI failed (Anthropic::RateLimitError)` → Free Tier 制限、課金 or 待機
- **新しい外部 API 連携を追加する時**:
  - SDK のメソッド単位 stub を採用 (= WebMock より相性良い)
  - `xxx_available?` パターンで credentials 未設定環境を守る
  - Static フォールバックを必ず用意
- **Render デプロイで詰まったら**:
  - Logs の末尾エラーを最優先で確認
  - 502 → Rails 起動失敗の再起動ループを疑う
  - `RAILS_MASTER_KEY` の文字数を `wc -c` で確認
