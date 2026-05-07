# Day 9 開発ログ (2026-05-07、4 モード運用初日 + リファクタ 6 本完走 + Tier 2 全 3 件完走)

Day 8 (= 5/6) 発表会後夜セッションで導入した「**4 モード切替型運用** (= 学習 / 新規機能 / リファクタ / 調査・計画)」の **実運用初日**。深夜帯のセッション 1 で `CalorieEquivalentService` の enum 化提案を構造ミスマッチで棄却 → ロジック / データ別ファイル分離 (PR #226) で完走。日中のセッション 2 では **ダッシュボード Tier 2 候補** (= `:iphone_with_data` 状態名のリネーム、Issue #161、Tier 2 旧 #5 = 後段の番号繰上げ前) を着手し、Issue 第一候補 `:user_with_data` を採用せず判定実態と一致する **`:has_data`** に変更 (PR #230) → 3 者並列レビュー全 Approve で完走。続くセッション 3 では **PR #95 由来の design-reviewer フォローアップ** (= 「唐揚げ 3 個 5 皿ぶん」 複合読み問題、Issue #99) に着手、`name + unit + 1 単位 kcal` の責務分離リファクタ (PR #232) で完走。続くセッション 4 では **ユーザー局長提案「concern 化はどうか?」 を構造的に検証して見送り判断**、`SessionsController` の 3 行重複を private method に抽出 (PR #237、Issue #228) → **「軽量 Issue は 3 者レビュー指摘を 1 PR で完結」 運用ルール初運用**。続くセッション 5 では **ダッシュボード Tier 2 候補 (= `CalorieAdviceService` の `body` フィールド整理)** に着手、`Result` Struct から `body` を分離して `ZeroKcalResult` を新設 (PR #239) → **「特殊ステートの表現方法」 を 4 段階判断軸として教材化 (= 学び 32)**。締めのセッション 6 では **ダッシュボード Tier 2 最終 1 件 (= `webhooks_controller.rb` の Service 切り出し)** に着手、ドメインロジックを `WebhookHealthDataIngestService` に切り出して controller 181 → 99 行 (-45%) にスリム化 (PR #241) → **「fat controller の Service 切り出し判断軸」 を学び 33 として教材化 + 「残置側にこそ判断ロジックを永続コメントで残す」 という strategic-reviewer 提唱を学び 33 核心実例として反映**。**1 日で 6 リファクタ完走 + ダッシュボード Tier 2 全 3 件完走 (= 更地化) + 道具選定の構造化シリーズ 4 例目 (= 学び 27 enum / 学び 30 Concern / 学び 32 特殊ステート / 学び 33 fat controller) 確立 + 「マージごと dev-log」 / 「軽量 Issue 1 PR 完結」 / 「dev-log も 3 者レビュー」 の 3 つの運用ルール確立**。

セッションの戦略テーマ (= セッション 1/2/4/5 が「**判断プロセス**」 系の教材、セッション 3 が「**運用標準化**」 系の教材):
1. (= セッション 1、判断プロセス) **enum という言葉から発想したユーザー提案を、構造ミスマッチで丁寧に棄却し、より筋の良いリファクタに着地させる対話プロセス**
2. (= セッション 2、判断プロセス) **Issue 起票時の第一候補をそのまま採用しない、名前が示す意味と判定ロジックを一致させる命名判断プロセス**
3. (= セッション 3、運用標準化) **データテーブル系リファクタで値変更とコメント追従を別作業として認識する、後追い未完を防ぐ grep 運用の標準化**
4. (= セッション 4、判断プロセス) **Concern 化提案を 4 観点 (= 共有相手 / 重複粒度 / 抽象化粒度 / テスタビリティ) のチェックリストで判定し、private method に着地させる道具選定の構造化**
5. (= セッション 5、判断プロセス) **特殊ステートの表現方法を 4 段階 (= predicate / factory / sibling Struct / Null Object) のグラデーションで判定し、データ shape の差を構造で表現する道具選定の構造化**
6. (= セッション 6、判断プロセス) **fat controller の Service 切り出しを 4 軸 (= 状態依存度 / 共有相手 / 責務カテゴリ / テスタビリティ) で判定し、特に「残置側」 のコードに「なぜ残したか」 の判断記録を永続コメントで残す道具選定の構造化**

---

## 🎯 Day 9 の目標

1. リファクタモードの実運用 (= ダッシュボードから 1 件 or ユーザー追加提案を選ぶ)
2. 「enum 化」 提案の構造的妥当性検証 → 採否判断
3. 採用案の実装 + 3 者並列レビュー通過 + マージ
4. 学び (= 「enum じゃなくファイル分け」 の判断記録) を後輩教材として残置

---

## 🏆 達成したこと (= PR #226 + #230 + #232 + #237 + #239 + #241 マージ + Issue #225 / #161 / #99 / #228 close + ダッシュボード Tier 2 全 3 件完走 (= 更地化) + 学び 27 / 28 / 29 / 30 / 31 / 32 / 33 確立 + リファクタモード定石フロー 8 ステップ初実証 + 「マージごと dev-log」 + 「軽量 Issue 1 PR 完結」 + 「dev-log も 3 者レビュー」 の 3 運用ルール確立 + 道具選定の構造化シリーズ 4 例目 (= 学び 27/30/32/33) 完成)

### マージ済み PR (= 6 本)

| PR | Issue | 内容 |
|---|---|---|
| #226 | #225 | refactor: `CalorieEquivalentService` の食品定数を `Foods` モジュールに別ファイル化 (= `Item` Struct + `ALL` 配列 (= 旧 `FOODS`、慣用名 ALL に改名) + `MIN_KCAL` を `app/services/calorie_equivalent_service/foods.rb` に集約、ロジック / データ分離リファクタ、enum 系ツール不採用の判断は本ファイル冒頭コメントで後輩教材として残置、`private_constant` は別ファイル化と Zeitwerk autoload 規約の都合で諦め、3 者並列レビュー後に🟡 軽微指摘 3 件 (= spec の旧定数名 `FOODS.shuffle` / `private_constant` 諦め理由表現の精度 / 旧実装コメントの歴史的事実) を追加コミット 21b918d で反映、spec 51 examples 無修正で全 PASS) |
| #230 | #161 | refactor: `BuildHomeDashboardService` の状態名 `:iphone_with_data` → `:has_data` リネーム (= PR #160 で判定順「データ優先」に変更後、旧名が誤称化していた問題の清算、Issue 第一候補 `:user_with_data` を採用せず判定実態 (= `exists?` の有無) と semantic 一致する `:has_data` を選択、4 状態 `:guest`/`:has_data`/`:android`/`:empty` で「最も判定に効く軸を名前にする」統一原則を確立、影響 5 ファイル +19/-27 行、ダッシュボード `docs/refactor-candidates.md` 候補 #5 削除 + #6 → #5 繰上げ、3 者並列レビューで code/strategic 両者から「day-8.md:73 の採用名ズレ」を共通指摘 → 本 dev-log 追記で吸収、spec 82 examples (= `build_home_dashboard_service_spec.rb` 38 + `home_spec.rb` 44) 全 PASS、rubocop 0 offenses) |
| #232 | #99 | polish: 食品 `name` に埋まった数量を `unit + 1 単位 kcal` に責務分離 (= 板チョコ「半分」 / 唐揚げ「3 個」 を name から外し、それぞれ 280kcal/枚 と 80kcal/個 に再設計、Issue #99 案 A (= name と unit と count の責務分離) 採用、副次の挙動変化として MIN_KCAL: 90 → 80 + 最大 kcal 食品: 唐揚げ → 板チョコ + unit 集合 5 種 → 4 種 をすべて意図化、foods.rb 冒頭に新規食品追加ガイドラインコメント (= ❌ 例 + 理由 1 行) を残置、3 者並列レビューで code/strategic 両者から「MIN_KCAL=90 コメント残存」 を共通指摘 → 追加コミット d52cfcd で反映 (spec 2 箇所 + service.rb 1 箇所)、フル spec 560 examples 0 failures、rubocop 0 offenses、design🟢 提案 2 件 + strategic🟢 提案 1 件は別 Issue 起票で吸収) |
| #237 | #228 | refactor: `SessionsController` の `create` web 経由ブランチ + `auto_login` の 3 行重複 (= reset_session + session[:user_id]= + redirect_to root_path notice) を `establish_session_and_redirect_home(user_id)` private method に抽出 (= ユーザー局長「concern 化はどうか?」 提案を 4 観点 (= 共有相手 / 重複粒度 / 抽象化粒度 / テスタビリティ) で構造的に検証 → 過剰抽象化と判断、private method に着地、判断記録は private method 直前のコードコメントに永続化、影響 1 ファイル +27/-6 行、既存 spec 25 examples 無修正で全 PASS、3 者並列レビューで code Approve / design 影響なし / strategic🟡 軽微 1 + 🟢 提案 3 を **本 PR 内で全吸収** (= 軽量 Issue ルール初運用、別 Issue 起票せず) → 追加コミット db055e6 で反映、rubocop 0 offenses) |
| #239 | (= ダッシュボード Tier 2 #5、refactor-candidates.md 由来) | refactor: `CalorieAdviceService::Result` Struct から `body` フィールドを分離、新規 `ZeroKcalResult` Struct に責務分離 (= 旧設計は body が 3/4 ケースで常に nil = デッドフィールド問題、データ shape が違う特殊ステートと通常ステートを 2 つの Struct で分離、view 側 duck type 互換のためデリゲートメソッド (= ZeroKcalResult に items=[] / button_label=nil / ai_used=false / Result に body=nil) で吸収、view 無修正、4 案検討 = 単一 Struct + factory method (= 最小、却下) / 専用 Result クラス分割 (= 中間、採用) / Null Object パターン (= 最大、過剰) / 現状維持 (= 撤退) のグラデーション、sibling 構造選択 (= Struct 継承アンチパターン回避)、3 者並列レビューで code🚨 Blocker候補 (= ZeroKcalResult 経路 spec 未検証) + ⚠️ Should fix + 💡 Nit + strategic🟡 4 案比較拡張 + 🟢 提案 2 を **本 PR 内で全吸収** (= 軽量 Issue ルール 2 例目) → 追加コミット 1442d9e で 5 件反映 → **Blocker候補は 0 歩 context 5 件追加で完全解消済**、build_home_dashboard_service_spec に ZeroKcalResult 経路の回帰防止スイート確立、フル spec 580 examples 0 failures、rubocop 0 offenses、ダッシュボード Tier 2 #5 削除 → Tier 2 残り 1 件 (= #4 webhooks_controller 切り出し) のみ) |
| #241 | (= ダッシュボード Tier 2 #4、refactor-candidates.md 由来) | refactor: `WebhooksController#health_data` のドメインロジック (= ペイロード検証 + パース + 永続化) を新規 `WebhookHealthDataIngestService` に切り出し (= 「fat controller を Service にどう剥がすか」 のお手本)、controller 181 → 99 行 (-45%) にスリム化、切り出し範囲 = `parse_recorded_on` / `parse_numeric` / `upsert_records` / `ISO_DATE_FORMAT` 定数 / `InvalidPayload` 例外 (= service へ昇格)、残置範囲 = `record_delivery!` / `read_raw_body` / `authenticate_webhook!` / `extract_bearer_token` / `MAX_BODY_BYTES` 定数 (= HTTP 入出力 + 認証 + 監査ログ)、失敗は **例外ベース** で controller の rescue ladder に委譲 (= 旧 `unless records_data.is_a?(Array)` 早期 return → service の `raise InvalidPayload` に統一)、3 者並列レビューで code Approve + design 影響なし + strategic🟡 軽微 1 (= 残置側判断記録の重要性) + 🟢 提案 3 を分類処理 → 本 PR 吸収 2 件 (= **A 残置側 record_delivery! 直前に 4 軸残置理由コメント追加 (= 学び 33 核心実例)** + **E service 冒頭に「unit spec を独立させなかった理由」 4 行コメント追加**)、別 Issue 起票 1 件 (= **#242 webhook_health_data_ingest_service_spec.rb 追加 = Tier 3 候補**)、dev-log 吸収 3 件 (= 経路 prefix 許容条件 / Before-After 記録 / 学び 33 学び 30 と半同型)、フル spec 585 examples 0 failures (= 既存 110 webhook + 8 webhook_delivery 計 118 examples 無修正)、rubocop 0 offenses、ダッシュボード Tier 2 #4 削除 → **Tier 2 全 3 件完走 (= 更地化)**) |

### close した Issue (= 4 件)

- **#225** (= 食品定数の別ファイル化、即日起票 + 即日 close) — PR #226 で close
- **#161** (= `BuildHomeDashboardService` の状態名リネーム、Day 8 起票 → Day 9 close) — PR #230 で close、最終採用名は `:has_data` (= Issue 起票時の第一候補 `:user_with_data` から協議で変更)
- **#99** (= 食品換算フォールバック文言読みづらさ、Day 5 起票 → Day 9 close) — PR #232 で close、案 A (責務分離) 採用、案 B (フォールバック専用コピー) と案 C (現状維持) は不採用
- **#228** (= `SessionsController` の private method 抽出、Day 9 セッション 4 で起票即着手) — PR #237 で close、Concern 採用見送り判断を Issue 本文に検証 4 観点付きで明記 + コードコメントに永続化 (= Day 8 `:user_with_data` → `:has_data` と類似の運用パターン)

### 起票した Issue (= 2 件、即日 close)

- **#225**: refactor: `CalorieEquivalentService` の食品定数を `Foods` モジュールに別ファイル化 (= 「なぜ enum でなくファイル分けか」の調査結果 + 設計判断を本文に明記、後輩がコピペで dev-log に使える形)
- **#228**: refactor: `SessionsController` のログイン後 session 確立ロジックを private method 抽出 (= 「concern 化見送り判断」 を Issue 本文に検証 3 観点付きで明記 → dev-log 化フェーズで観点 ④ テスタビリティを strategic-reviewer 補完追加し 4 観点判定テンプレに昇格、後輩教材として残置)

### 起票した v1.1 polish Issue (= 3 件、Day 9 セッション 3 末)

- **#234** (= 食品換算カードに「食べても帳消し！」 系の追記文言)
- **#235** (= 高 kcal 日フォールバックの絵文字ハイライト化)
- **#236** (= 唐揚げ系高頻度ヒット時のご褒美化リスク対応)

### 起票した Tier 3 候補 Issue (= 1 件、Day 9 セッション 6 由来)

- **#242** (= `webhook_health_data_ingest_service_spec.rb` 追加 = service unit spec 独立化、PR #241 code-reviewer + strategic-reviewer 共通🟢 提案を別 Issue 起票で吸収)

---

## 🧠 教訓ハイライト (= 7 件本日確立)

### 学び 27: enum 系ツールは「識別子 1 個の値リスト」用、属性付きレコードは「データテーブル」 として別ファイル分離

`CalorieEquivalentService::FOODS` の管理性向上のため、ユーザー局長から「enum 化したい」 提案。Claude が選択肢を整理:

| 種類 | 想定 | FOODS との適合 |
|---|---|---|
| Rails 標準 `enum` (ActiveRecord) | DB のカラムに整数を保存 → Symbol 表現 | ❌ Service は DB 不要 |
| `enumerize` gem | 属性 1 つの許可値定義 (= `role: [:admin, :user]`) | ❌ 4 属性同時管理は不可 |
| `ruby-enum` gem | Java 風の名前付き定数 + lookup | ❌ 各識別子に複数属性持てない |
| **配列 of Struct + 別ファイル** (= 採用) | データテーブル | ✅ 4 属性 (emoji/name/unit/kcal) のレコード × N 件を型安全に扱える |

つまり enum 系ツールは **「識別子 1 個の集合」** 用、`FOODS` は **「識別子 + 4 属性 (emoji/name/unit/kcal) のレコード × 10」** = **データテーブル** 構造。**構造ミスマッチ**。

enum 系で `FOODS` を表現すると「属性 1 個 (= name) は enum、残り 3 個は別 Hash」 の **二重管理** に陥る。データテーブルには素直に Struct 配列 + 別ファイル分離が筋。Java enum / TypeScript literal union / Python `Enum` でも同じ構造的制約あり。

→ 解決: ロジック (= `calorie_equivalent_service.rb` 本体) とデータ (= 新ファイル `calorie_equivalent_service/foods.rb`) の別ファイル分離を採用。foods.rb 冒頭で「なぜ enum でなくファイル分けか」 を後輩教材として残置。

How to apply:
- **enum を検討する時の最初の質問**: 「**識別子 1 個の集合か、属性付きレコードか?**」 を決める。前者なら enum、後者ならデータテーブル
- データテーブルには **配列 of Struct + 別ファイル** が筋。30-50 件まではこれ、それ以上なら YAML、ユーザー編集が入るなら DB、という段階論
- 「enum という言葉のイメージ」 ≠ 「Rails の enum 機能」 ≠ 「enum 系 gem の機能」。**初学者が混乱する場所だが、構造ミスマッチを言語化できると道具選定で迷わなくなる**
- **属性 1 個の集合か属性付きレコードか** は OOP / DB 設計の基本判断、enum に限らず効く視点

### 学び 28: リファクタ PR の 3 層線引き — コード / コードコメント / 歴史的 dev-log

PR #230 (= 状態名リネーム) の strategic-reviewer 提唱。リネーム refactor で「どこまで波及させるべきか」 を判断する時、対象を 3 層に線引きする:

| 層 | 扱い | 理由 | 参照先 (= 本 PR の実例) |
|---|---|---|---|
| ① コード / spec (= `app/`, `spec/`) | **全置換** | 動く実装と現状 spec は新名称で統一、混在は事故の元 | `app/services/build_home_dashboard_service.rb` 全体、`spec/services/build_home_dashboard_service_spec.rb`、`spec/requests/home_spec.rb` |
| ② コードコメント (= 同ファイル内) | **新軸名の意図を永続化** | 「なぜこの名前か」 を残置、PR description が消えてもコード単独で読める (= memory `feedback_code_as_communication.md` 整合) | `app/services/build_home_dashboard_service.rb:51` (= 「データの有無を最優先で見る軸名」 を新規追記) |
| ③ 歴史的 dev-log (= `docs/dev-log/day-N.md` の過去回) | **未編集** | 当時の実装状態 / 計画状態を述べる文脈なので書き換えると歴史改竄 = 教材として「設計バグ発覚 → 清算」のストーリーが追えなくなる | `docs/dev-log/day-3.md:13,116` / `docs/dev-log/day-8.md:73,113,282` (= 旧名 `:iphone_with_data` のまま意図的に残置) |

加えて **あわせて残した命名判断の記録**: Issue 第一候補 `:user_with_data` を採用せず `:has_data` にした経緯を PR description の比較表 + 本 dev-log で残す。後輩が「Issue 起票時の候補 = 最終採用ではない、リネームは判定ロジックと名前の意味を一致させて選ぶ」 を学べる。

How to apply:
- リネーム refactor のスコープ定義は **3 層線引き** を最初に宣言する (= PR description で「app/spec は全置換、コードコメントは新軸名で書き直し、歴史的 dev-log は未編集」 と明示)
- 「歴史的記録は当時の状態を述べる文脈なので未編集」 という言語化を覚えておく (= 後で「リネーム後の整合性」を求められた時の防衛線)
- Issue 第一候補と最終採用が異なる時は **dev-log に変更経緯を 1 段落** (= 本 PR で実証、code-reviewer + strategic-reviewer 両者からの共通指摘を吸収)
- リネームの判定基準: **判定ロジック (= `exists?` 等の操作) と状態名の semantic が一致するか** (= `:has_data` は `step_records.exists?` と一致、`:user_with_data` は user 軸が判定に効いていないので不一致)

### 学び 29: データテーブル系リファクタは「値変更」 と「コメント追従」 が別作業 — 数値リテラル grep を Test plan に組み込む

PR #232 (= 食品 name 構造改善) の strategic-reviewer 提唱。`Foods::ALL` の値を変更したリファクタで、3 者並列レビューの code/strategic 両者から **共通指摘** が出た: 「`MIN_KCAL = 90` が **インラインコメント / spec の section header に残存**、実装は 80 に変わっているのに数値だけ古い」。

実害ゼロ (= 論理は正しい、コメントの数値だけが古い) だが教材性のあるプロジェクトでは「**コメントの誤情報は混乱源**」 として駆除対象になる。

| 層 | 何をやるか | 忘れにくさ |
|---|---|---|
| ① 値変更 | データテーブルの数値 / 文字列を新値に | 忘れにくい |
| ② 計算式コメント | `# X = N のため Y >= N` の N を新値に | **見落とし常連** |
| ③ section header コメント | 「境界値: today_kcal = N」 の N を新値に | **見落とし常連** |
| ④ PR description / dev-log | 数値・挙動の記述 | 忘れにくい (= PR description は意識しやすい) |

**数値リテラル grep の運用化** (= Test plan のチェックリスト):

```bash
# 旧値 90 の残存確認 (= 本 PR で取り込んだ運用、ERE で旧値完全一致に絞る)
grep -rnE "MIN_KCAL\s*=\s*90|今 90|kcal < 90|today_kcal < 90" --include="*.rb" .
# → 0 件確認できればコメント追従完遂
# (BSD grep / GNU grep 双方で動作、`9` 始まりの無関係数値を拾わない)
```

How to apply:
- **データテーブル系リファクタの Test plan に「数値リテラル grep ヒット 0 件確認」 を必ず入れる** (= 学び 29 の中核運用、memory `feedback_grep_zero_after_fix.md` の派生)
- 値変更 PR では `grep -nE "[0-9]+ のため|MIN_KCAL = [0-9]+|<= [0-9]+|>= [0-9]+"` のような正規表現で旧値が残っていないかを push 前に確認
- 3 者並列レビューで「コメント追従」 系の共通指摘が出るのは構造上の必然 → 事前駆除すれば軽微反映の往復が 1 周減る (= 本 PR でも事前に grep していれば追加コミット d52cfcd は不要だった、教材として残置)
- **「値変更」 と「コメント追従」 を同じスコープ内の別タスクとして認識** (= 一括 sed では落ちる、目視 + grep の二段構え)

### 学び 30: Concern vs private method の判断は 4 観点をチェックリストで決める

ユーザー局長から「concern 化はどうか?」 提案 → 構造的に検証して **過剰抽象化と判断** → private method に着地 (PR #237、Issue #228)。Day 9 学び 27 (= enum vs ファイル分け) と同型の「**ユーザー提案を構造的に検証して着地**」 パターン。

**出典の経緯** (= dev-log の透明性): PR #237 description / Issue #228 本文では **3 観点** (= ① 共有相手 / ② 重複粒度 / ③ 抽象化粒度) を提示 → 本 dev-log 化フェーズで strategic-reviewer (= 自身) が観点 ④ テスタビリティを補完追加し、**4 観点判定テンプレに昇格**。 dev-log は PR の単純コピーではなく一段抽象化する場、補完したら経緯を残すのが筋 (= メタな学び)。

| 観点 | 判定基準 | 本 PR での結論 |
|---|---|---|
| ① 共有相手 | 同一クラス内のみか / 複数クラス間か | 同一 SessionsController 内 2 箇所のみ → Concern 不要 |
| ② 重複粒度 | 何行 × 何箇所か | 3 行 × 2 箇所 → private method 1 個で十分 |
| ③ 抽象化粒度 | CLAUDE.md「3 回ルール」 の **適用粒度** を確認 | 「3 回ルール」 は Concern / 基底クラス等の **構造的分離** に対する制約。同一クラス内 private 抽出は「整理」 のため 2 箇所でも適用可 |
| ④ テスタビリティ (= dev-log で補完) | 独立 unit test を書きたいか | 3 行 / redirect のみ → request spec で十分カバー、独立 unit test 不要 → Concern にする動機なし |

**Rails 慣習の言語化**: 同一コントローラ内重複は **private method**、複数コントローラ間重複は **Concern**。

How to apply:
- 「Concern 使ってみたい」 衝動が出た時は **4 観点をチェックリストで判定** (= 感覚で決めず、各観点に明確な答えを出す)
- 観点 ③ (= 抽象化粒度) の「3 回ルール」 適用範囲を読み違えると、後輩が「2 箇所で抽出するのはルール違反では?」 と誤読する → **コメントで適用粒度を明示** が必須
- 観点 ④ (= テスタビリティ) は Concern の隠れた採用動機。独立 unit test を書きたい時は Concern にする筋がある (= 4 観点で唯一 Concern 寄りに振れる軸)
- 判断記録は **private method 直前のコードコメント + Issue 本文 + PR description の 3 層** で永続化 (= memory `feedback_code_as_communication.md` 整合)

### 学び 31: 軽量 Issue は 3 者レビュー指摘を別 Issue 起票せず 1 PR 完結

PR #232 (= 食品 name 構造改善) では 3 者レビュー🟢 提案 3 件を別 Issue (#234 / #235 / #236) として起票したが、Day 9 セッション 4 で **「軽量 Issue (= 1 ファイル / +21 行 / ロジック影響なし) では 🟢 提案も本 PR 内で吸収」** ルール確立 (= memory `feedback_light_issue_one_pr_completion.md`)。本 PR #237 で初運用。

| Issue 種別 | レビュー🟡 軽微 | レビュー🟢 提案 |
|---|---|---|
| 中規模以上 (= 4 ファイル+ or ロジック横断) | 同 PR で吸収 | 別 Issue 起票 |
| **軽量 (= 1-3 ファイル / 局所変更)** | 同 PR で吸収 | **同 PR で吸収** (= 学び 31 確立) |

How to apply:
- 軽量 Issue 着手時、PR description の「レビュー方針」 セクションに「**🟡🟢 すべて本 PR で吸収予定**」 を事前明示 → レビュアーが「本 PR スコープ外」 と書く必要が減り、提案の往復が 1 周減る
- memory ファイル化 (= リポ外作業) などは「本 PR 内吸収」 から物理的に外れるので別タスク。ただし Issue は起票しない (= タスクリストで管理)
- 例外: 🟢 提案が「**別案件として独立した価値がある** (= 例: 別機能の改善)」 ものは別 Issue で良い (= 軽量 Issue 範囲を外れた提案)
- 教材性: 軽量 Issue 完全 close で「Issue : PR = 1 : 1」 の **追跡しやすい閉じ方** (= 経緯を 1 箇所で完結できる、後輩が起票 → 実装 → レビュー → マージ → 学びを 1 PR で読める) が実現する

### 学び 32: 特殊ステートの表現方法は 4 段階のグラデーションで判定する

PR #239 (= `CalorieAdviceService::Result` Struct の `body` フィールド分離) の strategic-reviewer 提唱。「特殊ステート (= 0 kcal 空ステート等、通常ステートとデータの持ち方 (shape) が異なる経路)」 を表現する道具選定を **4 段階のグラデーション** で判定する。

> **用語注記**: ここでの **shape** = Struct のフィールド構成 (= 「何の field を持つか」)、**behavior** = メソッドの振る舞い (= 「同じ field でも処理が違うか」)。

#### 4 段階の判定 table

| 段階 | 道具 | 適用条件 |
|---|---|---|
| 1 (最小) | 単一 Struct + `zero_state?` predicate のみ | shape (= フィールド構成) は同じ、意味だけ分けたい |
| 2 (最小+) | 単一 Struct + `Result.zero` / `Result.normal` factory method | shape 同じ、生成経路だけ意図化したい |
| **3 (中間、本 PR 採用)** | **Result + ZeroKcalResult sibling Struct** | **shape が違う (= デッドフィールド発生する)** |
| 4 (最大) | OOP 多態クラス分割 (= Null Object) | shape 違う + behavior (= 振る舞い) も違う + 多態必要 |

**判定軸**: **データの持ち方 (shape) が同じか違うか + 振る舞い (behavior) の多態が必要か**。

本 PR の判定:
- ❌ 段階 1/2: `body` フィールドが残る = デッドフィールド問題が解消されない
- ✅ 段階 3 (採用): `body` を ZeroKcalResult に分離、Result 側は 4 field でスッキリ
- ❌ 段階 4: 振る舞いの多態 (= AI 呼び出し等) は不要、Struct で十分

#### Day 9 道具選定の構造化シリーズにおける本学びの位置づけ (= 3 例目で完成)

学び 27 (= enum vs ファイル分け) + 学び 30 (= Concern vs private 4 観点) + 本学び 32 で **3 例目**。Day 9 で 3 例蓄積し判断テンプレが固まったマイルストーン。Day 10 以降の道具選定は同じ枠で記録する (= 後述の How to apply 末尾参照)。

| 学び | 判断対象 | 判定軸 |
|---|---|---|
| 27 | enum vs データテーブル | 識別子 1 個の集合か / 属性付きレコードか |
| 30 | Concern vs private method | 共有相手 / 重複粒度 / 抽象化粒度 / テスタビリティ |
| **32** | 特殊ステートの表現方法 | データ shape の違い / 振る舞いの多態の必要性 |

**共通パターン**: **「使ってみたい」 衝動を構造軸で機械的に検証する判断テンプレ**。後輩が「Concern 使いたい」 「enum 使いたい」 「Null Object 使いたい」 と言った時、構造軸で「適用条件に合うか」 を聞き返せる。

How to apply:
- 特殊ステートを表現する時、**まず段階 1 (= predicate のみ) から階段を上る** (= 過剰抽象化を避ける、最小から始める)
- 段階を上げる動機は「**shape の違い**」 (= 段階 3 へ) と「**behavior 多態の必要性**」 (= 段階 4 へ) の 2 軸のみ
- 「Null Object パターンを使ってみたい」 衝動が出た時は段階 4 が本当に必要か (= behavior 多態が要るか) を構造的に検証 → 不要なら段階 3 で着地
- sibling Struct (= 段階 3) は **inherit を選ばない** のが筋 (= Struct 継承は Ruby ではアンチパターン気味、duck type で完結する)
- view 側の互換性を保つ手段は **デリゲートメソッド** (= 「`def items = []`」 のような endless method) が最も読みやすい
- **「同じ枠で考える」 の運用ルール (= シリーズ 4 例目以降の書き方)**: Day 10 以降に新しい道具選定が出てきたら、**「使ってみたい衝動を構造軸で検証する枠」** (= 学び 27/30/32 と同フォーマット) で day-N の学び N に記録する。具体的には ① 判断対象 + 判定軸を 1 行で言語化、② 段階 / 道具 / 適用条件の table、③ 本 PR の判定 (= ❌ / ✅)、④ 共通パターン参照、の 4 セクション構造。後輩が読んだ時「自分もこのパターンで書ける」 と感じられる粒度を狙う。

### 学び 33: fat controller の Service 切り出しは 4 軸で判定 — **残置側にこそ判断記録を永続化** (= 道具選定シリーズ 4 例目)

PR #241 (= `WebhooksController#health_data` のドメインロジックを `WebhookHealthDataIngestService` に切り出し、Tier 2 #4 完走) の strategic-reviewer 提唱。**Day 9 道具選定シリーズ 4 例目** として確立 (= 学び 27 enum / 学び 30 Concern / 学び 32 特殊ステート / 本学び 33 fat controller)。

#### Service 切り出し判定の 4 軸

| 軸 | 判定基準 | 本 PR での結論 (parse_*/upsert_records vs record_delivery!) |
|---|---|---|
| ① 状態依存度 | controller state (= `@xxx`) に依存するか / 純粋関数的か | 切り出し側 = 純粋 (= 引数だけで動く) / 残置側 = `@raw_body` + `@webhook_user` 必須 |
| ② 共有相手 | 1 つの action 内のみか / 複数 action / 認証経路でも使うか | 切り出し側 = `health_data` のみ / 残置側 = auth 失敗経路 (= service 通過前) でも呼ばれる |
| ③ 責務カテゴリ | HTTP 入出力 / 認証 / ドメインロジック / 監査ログ | 切り出し側 = ドメインロジック / 残置側 = 監査ログ (= HTTP 経路ごとの出力) |
| ④ テスタビリティ | request spec で十分か / unit test を独立させたいか | 既存 webhook request spec 110 examples で網羅、unit spec は将来別経路追加時に検討 (Issue #242) |

**判定軸**: 4 軸の総合で「ドメインロジック軸が立つもの」 を service へ、「HTTP 経路結合軸が立つもの」 を controller に残す。

#### 学び 30 (= Concern vs private 4 観点) との **半同型** (= 重要)

学び 30 と完全同型ではなく **半同型** (= 3/4 軸が共通、1 軸が固有):

| 学び 30 の軸 | 学び 33 の軸 | 共通か固有か |
|---|---|---|
| 共有相手 | 共有相手 | ✅ 共通 |
| 重複粒度 | 責務カテゴリ | ✅ 共通 (= 観点の言語化が異なるが本質同じ) |
| 抽象化粒度 | (該当なし) | 学び 30 固有 (= Concern 化の 3 回ルール、service 切り出しでは判定不要) |
| テスタビリティ | テスタビリティ | ✅ 共通 |
| (該当なし) | **状態依存度** | **学び 33 固有** (= Concern は include で state 共有可能だが service は引数渡し必須、判定軸として比重大) |

→ 後輩が新しい道具選定で 4 軸を流用する時、「**どの軸が固有か**」 を知っておくと混乱しない。「**完全同型を主張せず、共通軸 / 固有軸を分けて示す**」 ことが教材としての誠実さ。

#### 残置側にこそ判断記録を永続化 (= 学び 33 の核心、本 PR で実演)

切り出した先 (= service) の spec / 命名はみんな丁寧に書く。**残った側 (= controller の `record_delivery!`) こそ「これは切り出さない」 という判断ロジックの永続記録が必要**。

具体実装 (= 本 PR `webhooks_controller.rb:74-79`):
```ruby
# 監査ログを WebhookHealthDataIngestService に切り出さず controller に残した判断 (= Tier 2 #4 教材ポイント、学び 33):
#   - 状態依存: @raw_body / @webhook_user に直接依存、純粋関数化するには 2 引数追加 = 切り出しコストに対する利益が薄い
#   - 経路共有: 認証失敗経路で **service 通過前に** 呼ばれる必要がある (= ingest service と独立)
#   - 責務分類: 監査ログは「HTTP 経路ごとの出力」 = controller 責務の範疇
#   - 切り出し側との対比: あちらは引数だけで動く純粋ロジック、こちらは controller state 必須
def record_delivery!(...)
```

**なぜこれが教材として最重要か**:
- 半年後の自分や後輩が「全部 service に出せばいいのでは」 と再リファクタしないためのアンカー
- PR description は GitHub に流れて読み返しコストが高い、**コードコメントが王道** (= memory `feedback_code_as_communication.md` 「コードを最強の伝達手段にする」 と直結)
- 切り出し判断 = 「何を切り出すか」 と「何を残すか」 は **対** で書いて初めて意図が伝わる

#### Service 名の経路 prefix 許容条件 (= 命名規約の補足)

`WebhookHealthDataIngestService` という命名は CLAUDE.md の規約「動詞+名詞」 から微妙に外れる (= `Webhook` 経路名 prefix が入っている)。

**経路 prefix 許容条件** (= 本 PR 由来):
- **複数経路が想定される時のみ経路 prefix OK** (= 例: 将来 Strava webhook が来た時、`StravaIngestService` と並べて `Webhook*IngestService` パターンで揃えられる)
- **単一経路 / 経路非依存の時は規約「動詞+名詞」 を守る** (= 例: `BuildHomeDashboardService` / `CalorieEquivalentService`)

→ 後輩が真似する時の判断基準 (= 「経路 prefix 入れていいか?」) が明確になる。

How to apply:
- fat controller を見たら **4 軸 (= 状態依存度 / 共有相手 / 責務カテゴリ / テスタビリティ) で機械的に判定**
- 切り出した先だけでなく **残置側のコードに「なぜ残したか」 4 軸コメント** を必ず書く (= 学び 33 の核心実例、本 PR で実演)
- 学び 30 (= Concern vs private 4 観点) との **半同型** を意識 (= 3/4 軸共通、状態依存度は service 切り出し固有)
- 例外ベースの失敗伝播 (= controller の rescue ladder 統一) を採用する条件: **3 種以上の失敗経路が並ぶ時** (= 本 PR は JSON parse / InvalidPayload / RecordInvalid の 3 種で分岐点超え)
- Service 名の経路 prefix は **複数経路想定の時のみ OK** (= 例: `WebhookXxxService` / `StravaXxxService` で対称性確保)
- request spec で網羅できるなら **unit spec を機械的に追加しない** (= 「Service 切り出し = 即 unit spec 追加」 のアンチパターン回避、必要になったら追加: Issue #242 候補)
- 「fat controller 解消の Before/After」 = 行数だけでなく **責務分類の Before/After** が教材として効く (= 「HTTP / 認証 / ドメイン / 監査」 の 4 カテゴリで before どこにあったか / after どこにあるか)

---

## 🔥 つまずき / 学び (= 本日 2 件)

### 1. `private_constant` と Zeitwerk autoload の両立難 (= PR #226 設計判断)

`Foods` モジュール自体を `private_constant :Foods` で外部隠蔽したかったが、Rails 8 + Zeitwerk では `Foods` のロードが遅延評価されるため、親ファイル (= `calorie_equivalent_service.rb`) で `private_constant :Foods` を書くと **Foods 定数がまだロードされていない時点で宣言が走り NameError リスク** がある。

回避策は明示 `require_relative "calorie_equivalent_service/foods"` で先に読み込む手があるが、Rails の autoload 慣習を尊重して **別ファイル化と引き換えに諦めた**。各定数は `freeze` 済で外部書き換え不可、実害なし。元コードの `Item` / `FOODS` / `MIN_KCAL` 全 3 件の private_constant を清算。

How to apply:
- **Rails autoload と private_constant の両立** は別ファイル化と相性が悪い。片方諦める判断を明示する
- 諦める時はコードコメントで「**何を / なぜ / 代替策**」 を残置 → 後輩が判断追える
- 関連 strategic-reviewer 評価: 「**得たもの (= 別ファイル分離 + 教材性) > 失ったもの (= 名前空間カプセル化)**」

### 2. 3 者並列レビューで指摘された「歴史的事実コメントの保存」

`calorie_equivalent_service.rb` 32 行目の旧実装参照コメントを本リファクタで `Foods::ALL.sample` に書き換えてしまい、design-reviewer から「**旧実装は当時 `FOODS.sample` だったので歴史的事実として `FOODS.sample` のままにすべき**」 と指摘 → 戻す。

→ 解決: 「過去の状態を指すコメント」 は **その時点の表記をそのまま残す** のが正しい。リファクタで一括置換すると「旧実装も新名称を使っていた」 と誤読される。

How to apply:
- リファクタ時の名前変更で、コメント内の **歴史的参照 (= 「旧実装の XXX」「以前は YYY」)** は触らない
- 名前変更前後の対応関係を別途残したい場合は「(= 当時 FOODS、現 Foods::ALL)」 のような注記で対応
- 一括 grep + sed で名前置換する時は **コメント文も対象に入る** ので別途レビューが必要

---

## 🤝 ユーザー (= 本人) の判断ハイライト

1. **「A→Bでお願いします」** (= 俯瞰マッピング → 縦堀り の 2 段階アプローチ採用、自分のペースで学ぶ意思)
2. **「もっと初歩的なところから始めたほうがいいですね、学び方も変えたほうがいい」** (= Lesson 1 の詰め込み失敗を即フィードバック、メタ視点での運用変更指示)
3. **「A案で復習も含めて全部わからない体で話を進めさせてください」** (= 完全初学者ベースで学ぶ姿勢、知ったかぶりを排除)
4. **「モチベーションや必要に合わせてやることを変えたい」** (= 4 モード切替型運用の根源判断、自由度と継続性の両立)
5. **「ダッシュボードだけでなくそれ用のサブエージェントも作りますか?」** (= 過剰最適化を疑って Claude に問う、刈込原則発動)
6. **「Bやって早速リファクタリング作業をやりましょう。もちろん別ISSUEで」** (= レビュー指摘 🔴 だけ反映してリファクタへ即移行する判断、勢い継続)
7. **「food enum 化しませんか?」** (= 軽量リファクタ提案、初リファクタとして適切な粒度を直感)
8. **「gem enumって使えないんでしたっけ?」** (= Rails enum がダメと聞いて、別の選択肢を探す柔軟性 + 自分の理解不足を素直に問う姿勢)
9. **「A案でいきましょう! 多分私しかしないと思うのですがなぜenumじゃなくてファイル分けなのかも後でサマリー化するときに追記してください」** (= 採否判断 + 自分以外の読者がいない前提でも教材化する姿勢、後輩教材ではなく未来の自分への記録という独自の動機)
10. **「マージしました」** (= PR 完走確認 × 3、4 モード運用初日に PR #222 / #224 / #226 の 3 PR を完走)

---

## 📊 統計

- マージした PR: **6 本** (= #226 リファクタ初運用 + #230 ダッシュボード経由初リファクタ + #232 design-reviewer フォローアップ清算 + #237 軽量 Issue 1 PR 完結ルール初運用 + #239 道具選定構造化シリーズ 3 例目 + #241 Tier 2 完走 + シリーズ 4 例目)
- close した Issue: **4 件** (= #225 即日起票即日 close、#161 Day 8 起票 Day 9 close、#99 Day 5 起票 Day 9 close、#228 即日起票即日 close)
- 起票した Issue: **6 件** (= 即日 close 2 件 [#225 + #228] + open 残 4 件 [v1.1 polish 提案 #234 / #235 / #236 + Tier 3 候補 #242 webhook service spec])
- ダッシュボード Tier 2: 開始時 3 件 (#4 / #5 / #6) → **終了時 0 件 (= 全 3 件完走、Tier 2 更地化)** (= #4 = webhooks Service 切り出し済 / #5 = #161 リネーム済 / 旧 #6 = #5 繰上げ後 body 分離済)
- spec: **585 examples** (= 557 → 560 (+3 by PR #232 食品データ再設計) → 580 (+20 by PR #239 ZeroKcalResult 経路 spec 追加) → 585 (+5 微調整、PR #237/#241 は spec 無修正)
- rubocop: **0 offenses**
- 教訓: **7 件** (= 学び 27 + 28 + 29 + 30 (= Concern vs private 4 観点判定) + 31 (= 軽量 Issue 1 PR 完結) + 32 (= 特殊ステート 4 段階グラデーション) + 33 (= fat controller の Service 切り出し 4 軸 + 残置側判断記録))
- つまずき / 学び: **2 件**
- セッション時間: **6 セッション** (= セッション 1: 0:00 過ぎ〜4:00 深夜帯 PR #226 / セッション 2: 日中 PR #230 / セッション 3: 日中後半 PR #232 / セッション 4: 日中末 PR #237 / セッション 5: 日中末追加 PR #239 / セッション 6: 締め PR #241)

---

## 🎯 残タスク

### 直近 (= Day 10 以降)
- [ ] リファクタダッシュボード自身の改善 (= Issue #223、🟡 まとめ: Tier 定義明示 / やらない候補セクション / 教材性追記 / 漏れ候補 3 件 (N+1 監査 / RSpec カバレッジ空白マップ / Solid Queue・Cache 本番運用検証))
- [ ] Lesson 7 (= クラスメソッド `def self.xxx` or if 文 or 継承 `<` 候補)
- [x] ~~ダッシュボード Tier 2 残り 1 件~~ → **Day 9 セッション 6 で完走、Tier 2 全 3 件更地化** (= #4 webhooks Service 切り出し PR #241 / #5 旧 BuildHomeDashboardService state 命名 = Issue #161 PR #230 / #6 → #5 繰上げ後 CalorieAdvice body 分離 PR #239)
- [ ] Tier 1 大物 3 件 (= Phase 3 三重防衛 / Capacitor OAuth ブリッジ / daisyUI 全置換) — Day 10 以降で着手検討
- [ ] Tier 3 候補 (= 発見次第追記、現状 Issue #242 webhook service spec 追加のみ)
- [ ] Day 9 セッション 3 由来 v1.1 polish Issue 3 件: **#234** (= 食品換算カードに帳消し系コピー) / **#235** (= 高 kcal 日フォールバックの絵文字ハイライト化) / **#236** (= 唐揚げ系の高頻度ヒット時のご褒美化リスク対応)
- [ ] memory `feedback_issue_as_decision_log.md` 起こし (= Day 8 + Day 9 セッション 4 strategic🟢 提案 5、Day 8 `:user_with_data` → `:has_data` 経緯 + Day 9 Concern 見送り経緯の 2 事例集約、リポ外作業)

### 中期 (= v1.0 / v1.1)
- [ ] 子 5b (= WorkManager 自動同期、~3-5h)
- [ ] 子 7 (= APK ビルド + sideload 手順、~1h)
- [ ] Tier 1 大物 3 件 (= Phase 3 三重防衛 / Capacitor OAuth ブリッジ / daisyUI 全置換)

---

## How to apply

- **次セッション (= Day 10)**: モード宣言で再開地点を指定 (= Day 8 で確立したフロー)
  - 「今日は学習」 → `project_ruby_basics_learning_track.md` から Lesson 7 候補を提示
  - 「今日はリファクタ」 → `docs/refactor-candidates.md` から次の 1 つ
  - 「今日は新規機能」 → GitHub Issues + Projects board
  - 「今日は調査・計画」 → plan-issue skill or api-researcher
- **enum を検討する時**: 「識別子 1 個の集合か、属性付きレコードか」 を最初に問う (= 学び 27)
- **リファクタモードの定石フロー (= 本日確立)**:
  1. ダッシュボードから 1 つ選ぶ (or ユーザー追加提案を受ける)
  2. 提案の構造的妥当性検証 (= 道具選定が正しいか)
  3. 別案検討 (= 必要なら 2-3 案でユーザー判断、勝手に決めない)
  4. Issue 起票 (= 「**なぜこの案か**」 を本文に書く、後輩教材として、または自分の未来の参照として)
  5. ブランチ + 実装 + spec 緑確認 (+ rubocop 0 offenses)
  6. PR 作成 → 3 者並列レビュー依頼 (= code-reviewer / strategic-reviewer / design-reviewer)
  7. 軽微 🟡 反映 → 必要なら追加 commit → merge
  8. dev-log day-N に PR + 学び を記録 (= マージ直後、鮮度命)
- **歴史的事実コメントの扱い**: リファクタで名前変更しても、過去状態を指すコメント内の名前は触らない (= 学び 2 件目)
