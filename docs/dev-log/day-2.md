# Day 2 開発ログ (2026-05-01)

GW 2 日目。Day 1 で立ち上げた骨組みに、認証 / テスト基盤 / Stimulus / 運用フローの肉付けをする日。「絵に描いた仕組み」化していた `/plan-issue` を実戦に乗せて、6 PR 完走で締めた。

---

## 🎯 Day 2 の目標

1. Day 1 から持ち越した **RSpec 導入** と **Google OAuth** を片付ける
2. **スクール公開前の発表前 Blocker** (ホームダミー除去) を消化
3. **Stimulus 初導入** で Hotwire 路線を確立
4. フリーライフ流の運用フロー (`/plan-issue` + 3 者並列レビュー) を実戦に乗せる
5. Day 3 以降の本命 (Apple Shortcuts Webhook) に集中できる状態を作る

---

## ✅ 達成事項

### 9 PR 完走

| PR | Issue | 内容 | コミット (squash 後) |
|---|---|---|---|
| #5 | #4 | main 直 push を阻止する二段構えガード | `cefe63c` |
| #7 | #6 | `/plan-issue` スラッシュコマンド | `17bbc97` |
| #10 | #9 | RSpec 導入 + /about TDD 教材サンプル | `ac5e76a` |
| #12 | #11 | Google OAuth (omniauth、Devise なし) | `1d2eccb` |
| #14 | #13 | ホームダミー除去 + 仮ログイン UI 正規化 | `68f51bf` |
| #16 | #15 | フラッシュ自動非表示 Stimulus | `0edcf45` |
| #18 | (なし) | サブエージェント間引き継ぎテンプレ整備 | `0b7a67d` |
| #19 | (なし) | rubocop 既存違反 fix (PR #14 以降の CI 赤を解消) | `b6ecee4` |
| #20 | (なし) | OAuth credentials 移行 + 本番 fail-fast バリデーション | `eedade3` |

### `/plan-issue` 実演 — 3 ルート全完走

PR #7 マージ後、strategic-reviewer の Conditional Go 条件として「絵に描いた仕組み化」を防ぐためのドッグフード化を約束していた。

- **(C) 中止ルート**: 動作確認のみで終了
- **(B) Backlog 追記ルート**: **Backlog Issue #8** を自動作成 + 1 行追記 (`w-96` モバイル対応)
- **(A) Issue 起票ルート**: Issue #9 起票 → そのまま実装着手

3 ルートすべてが対話 → 副作用 (Issue 起票/追記) → 実機確認 まで通り、Conditional Go 条件達成。

### 二段構え hook の発動確認 (PR #5)

`.claude/hooks/block-main-push.sh` (Claude Code PreToolUse) と `.githooks/pre-push` (Git 側) の両方が `git push origin HEAD:main` を物理ブロックすることを実機 e2e で確認。本セッション中は誤って main 直 push を試みる場面はなかったが、安全網としての価値が出ている。

### 認証 / テスト基盤の整備

- **RSpec + FactoryBot** 最小構成 (capybara/cuprite/shoulda-matchers/simplecov は **意図的に保留** — system spec を書く動機が立った Issue で導入する方が後輩に伝わる)
- **Google OAuth** (`omniauth-google-oauth2` + `omniauth-rails_csrf_protection` + `dotenv-rails`)
  - Devise は採用せず手書き SessionsController (ソーシャル一本化方針なら overengineering)
  - User モデルは `provider + uid` 設計で **将来 Apple ID 増設可能** な布石
- **Stimulus 初導入** (`flash_controller.js`)
  - 自動非表示 (3 秒) + 閉じるボタン (×) の最小サンプル
  - 既存の `eagerLoadControllersFrom` に乗るだけで動く (config 追加なし) ことを実証

### Backlog Issue #8 の蓄積 (継続管理)

`/plan-issue` (B) ルートで作った常時オープン Backlog に Day 2 中に 6 アイテム蓄積:

- ホーム画面 `w-96` モバイル対応
- system spec 導入時に capybara + cuprite を追加
- `/about` ページ拡張 (使い方ページとして)
- × を `✕` (U+2715) や SVG icon に置換
- フェードアウトアニメーション
- `<span>` に `flex-1` / alert に `justify-between` (長文対応)

### サブエージェント引き継ぎテンプレの整備とドッグフード (PR #18)

各 `.claude/agents/<name>.md` に「依頼時に渡してほしい情報」セクション + 依頼例を追加し、複数エージェント横断パターン (3 者並列レビュー / rails-implementer → test-writer 引き継ぎ / api-researcher → rails-implementer 引き継ぎ) を `docs/agent-templates.md` に集約した。

- **設計判断**: C 案 (各 agent.md に同梱) + B 案 (横断パターンのみ docs/ に集約) のハイブリッドを採用
- **ドッグフード**: 本変更自体を 3 者並列レビューでレビュー。code-reviewer 🟡 / strategic-reviewer 🟢 + 戦略提案 / design-reviewer 🟡 (UI 変更なしのため「教材性 = 後輩が読んで使えるか」観点) で合計 8 件の指摘を反映
- **形骸化防止**: PR description に「次の本命 PR で実演 → Day 開発ログに 3 行所感を残す」セルフ約束を明記。実演結果は本ログ末尾「依頼テンプレ実演結果」を参照

### main の CI 赤放置を発見・解消 (PR #19)

PR #18 の CI で lint fail が出た際、変更がドキュメントのみだったため調査。**PR #14 以降 3 PR 連続で CI が failure のまま main にマージされていた** ことが判明。`config/initializers/omniauth.rb:13` の `[:post]` と `db/migrate/20260501051150_create_users.rb:13` の `[:provider, :uid]` が rubocop-rails-omakase の `Layout/SpaceInsideArrayLiteralBrackets` 違反 (内側スペース欠落) で残っていた。

- 機械的な fix (`[ :post ]` / `[ :provider, :uid ]` への修正のみ)
- 本 PR 後は **「マージ前に CI green を確認する」** を運用に組み込み (memory にも追記)

### OAuth credentials 移行 + 本番 fail-fast バリデーション (PR #20)

Day 5 デプロイ前の秘密管理統一を Day 2 中に前倒し。`config/initializers/omniauth.rb` の Google Client ID / Secret 読み込みを **credentials 優先 + ENV フォールバック** 式 (`Rails.application.credentials.dig(:google, :client_id) || ENV["GOOGLE_CLIENT_ID"]`) に変更。

- **本番限定 fail-fast** を同梱: 両方未設定なら `Rails.env.production?` ガード内で `raise` して起動を物理的に止める
- レビュー反映で fail-fast を別 PR ではなく本 PR に取り込む判断 (副局長の論拠: **「変更点 A の安全性が変更点 B に依存しているなら、A と B は同一 PR で入れる」**)
- 設計意図を omniauth.rb 先頭にコメント 3 行で永続化 (PR description だけでは時間で流れる)
- Day 5 デプロイ前のチェックリストは `memory/project_day3_kickoff.md` に追記済み

### Day 1-2 全体で完走した PR (リポジトリ通算)

- Day 1: PR #1, #3
- Day 2: PR #5, #7, #10, #12, #14, #16, **#18, #19, #20**

---

## 🔥 遭遇したトラブルと解決

### トラブル 1: api-researcher が WebSearch / WebFetch 権限なしで失敗

**症状**: Apple Shortcuts Webhook の仕様調査を `api-researcher` に依頼したが、「WebSearch も WebFetch も利用できない状況」と返された。記憶ベース回答も古いリスクがあるため空振り。

**経緯**:
1. Issue #11 (OAuth) と並行で `api-researcher` を background 起動
2. 仕様調査が Web 検索を必要とするためツール権限が必須
3. 当該セッションでは権限が付与されておらず、調査ステップが完全に空振り

**解決**: 仕様調査を一旦保留。OAuth と他の実装を巻取り。Day 3 で `api-researcher` 再起動の前に Claude Code の `permissions.allow` に `WebSearch` / `WebFetch` を追加して権限付与する想定。

**学び**:
- サブエージェントが特定ツールに依存する場合、起動前に **権限付与状況を確認** する
- Web 調査が必要な依頼は Claude Code の settings に WebSearch / WebFetch を allow する必要がある
- 「待ち時間ブロッカー」は credentials 発行だけでなく **仕様調査でも発生** する。早めに前提を整えておくと後で詰まらない

### トラブル 2: PR #12 で 1 ラウンド目に Blocker が 5 件挙がった

**症状**: Google OAuth (PR #12) の 3 者並列レビューで code-reviewer が Blocker 3 件、design-reviewer が Blocker 2 件を挙げた。

**Blocker の内訳**:
- code-reviewer:
  - **Session Fixation 対策**: `reset_session` を `session[:user_id] = user.id` の前に呼んでいない
  - `OmniAuth.config.silence_get_warning = true` と `allowed_request_methods = [:post]` の矛盾設定
  - `request.env["omniauth.auth"]` が nil の場合のガード抜け
- design-reviewer:
  - `<main>` の `mt-28` (112px) でヘッダとホームカードが重なる
  - フラッシュメッセージとホームカードの視覚的断絶 (mt-28 派生)

**解決**:
1. 全 Blocker を 1 コミットで反映 (`refactor: PR #12 レビュー指摘を反映`)
2. マージ前に **再度 3 者並列レビュー** を実施 (重要箇所は再レビュー必須を運用に組み込む)
3. 再レビューで全員 Go を確認してマージ

**学び**:
- セキュリティ系の指摘 (特に Session Fixation) は **設計時に想定しないと出ない罠** が多い。レビューで担保する仕組みが必須
- 重要な PR では **修正後の再レビューを運用に組み込む** べき (PR #14 / PR #16 でも踏襲、毎回 Go 判定を獲得)
- レビュー反映コミットのメッセージは **「指摘との対応関係」を `[code-reviewer] / [design-reviewer]` のカテゴリ別に列挙する** 形が後で読みやすい

### トラブル 3: `User.from_omniauth` の `find_or_create_by` の罠

**症状**: Issue #11 本文には `find_or_create_by(provider, uid)` で書く想定だったが、実装段階で気付いた:

> `find_or_create_by` のブロックは **create 時にしか属性更新されない**

つまり既存ユーザーの再ログイン時に `email` / `name` / `image_url` の最新化が行われない。Google アカウントの表示名やアイコン変更が反映されない。

**解決**: `find_or_initialize_by` + `assign_attributes` + `save!` パターンへ変更。

```ruby
def self.from_omniauth(auth)
  user = find_or_initialize_by(provider: auth.provider, uid: auth.uid)
  user.assign_attributes(
    email: auth.info.email,
    name: auth.info.name,
    image_url: auth.info.image
  )
  user.save!
  user
end
```

PR 本文に「Issue 本文の表記から外れたが、ログイン毎の属性更新を取り込むため `find_or_initialize_by` パターンを採用」と判断ロジックを残した。

**学び**:
- Active Record の `find_or_create_by` のブロックは **新規作成時のみ走る** ことを忘れない
- ログイン毎の属性更新を求めるなら `find_or_initialize_by` + `assign_attributes` + `save!` パターン
- Issue 本文と実装が異なる選択になった場合、PR 本文に判断ロジックを残せば再現性が担保できる

### トラブル 4: design-reviewer が PR #14 まで `<meta name="application-name">` を見落としていた

**症状**: PR #12 のマージ後 design-reviewer の再レビューで「`<meta name="application-name" content="App">` が `App` のまま」が **新規発見** として出た。これは PR #3 (daisyUI 統合) からあった問題。

**経緯**:
1. PR #3 のレビューでは見落とし
2. PR #12 で `<title>` の `App` フォールバックを修正 → 関連箇所に気付く
3. PR #14 (ホームダミー除去) のスコープに含めて修正

**解決**: PR #14 のスコープに「`<meta name="application-name">` 修正」を含めて反映。

**学び**:
- レビュアーも見落とすことがある。**設計上の関連箇所** (今回は `<title>` ↔ `<meta application-name>`) はワンセットで指摘される運用にすべき
- 派生 Issue (前 PR で見落としたもの) を後続 Issue のスコープに含める判断は妥当。「掃除」系 Issue にまとめる方が筋

### トラブル 5: PR #14 以降 3 PR 連続で CI 赤いまま main にマージしていた

**症状**: PR #18 (ドキュメント追加) を作ったところ、Ruby ファイルを 1 行も変えていないのに CI lint が fail。原因調査で **PR #14, #16, #17 の 3 件が CI failure のまま main にマージされていた** ことが判明。

**経緯**:
1. PR #12 (Google OAuth) で `[:post]` / `[:provider, :uid]` の rubocop 違反が混入
2. 当時のレビューでは内容観点で 3 者並列レビューを通したが、機械的 lint チェックを運用フローから見落とし
3. 以降 3 PR (#14, #16, #17) も CI 赤を放置したまま進行
4. PR #18 の CI 失敗を契機に発覚

**解決**:
1. fix 専用の PR #19 を作って 4 件の違反を機械的に修正 (`[ :post ]` / `[ :provider, :uid ]`)
2. PR #18 を main に rebase し再 CI を走らせて green を確認してマージ
3. **「マージ前に `gh pr checks <PR#>` で green 確認する」** を運用フローに組み込み (`memory/project_day3_kickoff.md` 末尾「How to apply」に追記済み)

**学び**:
- 3 者並列レビューは内容観点では機能するが、**機械的 lint チェックは別プロセス**。レビューフローと CI green 確認の両方を運用に組み込む必要がある
- main の CI 状態は **3 PR 程度なら気付かないまま積める**。新規 PR の CI が落ちて初めて見つかる構造的な穴
- 修正自体は `bundle exec rubocop --autocorrect` ではなく手動で書き直した (-A 必須の Layout 系は autocorrect 範囲外なので手で 4 行修正)

---

## 📝 Day 2 で確立した運用フロー

```
1.  git checkout main && git pull origin main
2.  /plan-issue <トピック> で対話 → Issue 起票
3.  git checkout -b feature/<機能名>
4.  必要なら api-researcher を起動 (要 WebSearch/WebFetch 権限)
5.  rails-implementer で実装、または直接実装
6.  test-writer で RSpec 追加
7.  git add + commit + push + gh pr create --base main
8.  3 者並列レビュー (code-reviewer + strategic-reviewer + design-reviewer を 1 メッセージで並列起動)
9.  Blocker / Should-fix を反映 (重要箇所では再レビュー必須)
10. gh pr merge <PR#> --squash --delete-branch
11. git checkout main && git pull origin main && git fetch --prune
```

このフローを Day 2 中に **6 PR で繰り返した**。再現性が確認できたので Day 3 以降も継続。

---

## 🎓 主要な学び

### TDD / RSpec (PR #10)
- **Red コミットを単独で残すと、後で読む人にも「この時点では落ちていた」が証拠付きで伝わる**。TDD は口で説明するより 1 つの PR で見せた方が早い
- `test-writer` サブエージェントの動作確認は **最初は単純な題材で「呼び方を体得」する** 方針が有効

### スコープ判断
- **スコープ最小逸脱** (Issue 内で別件を扱う) は **PR 本文に判断ロジックを残す** ことで再現性を担保できる
- **締切前は待ち時間ブロッカーを先に解放する** (Google OAuth credentials 発行が典型例)
- 「**掃除**」と「**コピー強化**」は分離する (PR #14)。Hero キャッチを本 Issue で確定すると将来の検討機会が失われる

### OAuth / 認証 (PR #12)
- **Devise = 簡単** はメール+パスワード+確認メール込みフルセット時の話。**ソーシャル一本化なら自前 omniauth + has_secure_password の方がコード量も理解コストも低い**
- **Session Fixation 対策**: 認証成功時に必ず `reset_session` を呼んでから session に書き込む。`destroy` も `reset_session` で揃える方が一貫性◎
- **provider + uid 複合 unique index** は OAuth の鉄則 (Apple ID / GitHub などの追加がレコードが増えるだけになる)

### Stimulus / Hotwire (PR #16)
- **`disconnect()` で副作用 (タイマー / イベントリスナー) を片付ける** のは Turbo 環境では必須事項 (メモリリーク防止)
- 独自 action (`close()` 等) でも明示的にタイマーを clear するのが堅牢 (Mutation Observer 依存を排除)
- `eagerLoadControllersFrom` 構成では **ファイル名 `flash_controller.js` を置くだけで `data-controller="flash"` が動く** (config 追加なし)

### レビュー運用
- **重要箇所 (セキュリティ系・アクセシビリティ系) は再レビュー必須** (PR #12, #14, #16, #20 で実証)
- **回帰防止 spec で「設計上禁止したいもの」を `not_to include` で明示** すると、設計意図のドキュメント化になる (PR #14 の Primary/Secondary/Accent 否定アサーション)
- **マージ前に `gh pr checks <PR#>` で CI green 確認** を運用に組み込み (PR #19 で発覚した CI 赤放置事故への対策)

### サブエージェント運用 (PR #18 で確立)
- **完了報告フォーマット (出力側) と依頼テンプレ (入力側) は両方そろえる**: 出力だけだと依頼者ごとに渡す情報がブレて引き継ぎが事故る
- **横断パターン (3 者並列レビュー / 引き継ぎ) は個別 agent.md に置けないので `docs/agent-templates.md` に集約**: ハイブリッド構成で齟齬を避ける
- **テンプレ自体をドッグフードでレビューする**: 作って終わりにせず、最初の対象 PR で実演 → 開発ログに所感を残すループで形骸化を防ぐ

### 秘密管理 / デプロイ準備 (PR #20)
- **本番=credentials, 開発=.env, 末尾で fail-fast** が Rails 8 の素直な分け方。フォールバック式 `credentials.dig || ENV` は便利だが「両方未設定でも動いてしまう」ので production 限定の起動時 raise を必ず添える
- **「変更点 A の安全性が変更点 B に依存しているなら、A と B は同一 PR で入れる」** (今回 fail-fast を別 PR にせず credentials 移行 PR に同梱した判断軸)
- **伝達手段の優先順位は コード (fail-fast / 永続コメント) > ドキュメント > memory > 口頭** (strategic-reviewer 学びポイント)。コードに埋め込めるなら最優先

### ツール導入の判断軸
- **プラグイン / gem / ツール導入時は現在の技術スタック相性を最優先軸とする** (Hotwire ベース Rails に React 前提の Anthropic 公式 `frontend-design` プラグインは不適合と判断)

---

## 🎓 依頼テンプレ実演結果 (PR #18 セルフ約束の回収)

PR #18 で「次の本命 PR で依頼テンプレを実演 → 3 行所感を開発ログに残す」と約束。PR #20 (credentials 移行) で実演した所感:

1. **2 者並列レビュー (code + strategic) は 1 メッセージで起動 → 効果絶大**。再レビュー時の「修正コミット SHA + 反映ロジックをカテゴリ別」記法も Day 2 既存運用とそのまま接続できた
2. **重要箇所の再レビューが本当に効く**: 1 ラウンド目で `||` フォールバックを「Approve」していたら、本番の "静かな事故" を見逃していた可能性。fail-fast 同梱の判断につながった
3. **テンプレが「呼ぶ側の思考整理ツール」になった**: 「自信が無い箇所」「重点観点」を埋める段階で自分の不安が言語化される副次効果あり

→ Apple Shortcuts Webhook (Day 3 本命) で **3 者並列レビュー + rails-implementer / test-writer / api-researcher の引き継ぎ含むフルセット** を回す。これで全エージェントの依頼テンプレが実戦投入される。

---

## 📌 Day 3 への積み残し

| 優先 | タスク | 工数 | 備考 |
|---|---|---|---|
| ✅ | ~~Rails `credentials.yml.enc` への移行~~ | 完了 | Day 2 中に PR #20 で消化 |
| 🥇 | Apple Shortcuts → Webhook 受信 | 大 (半日〜1 日) | 要 `api-researcher` の WebSearch / WebFetch 権限プリチェック |
| 🥈 | Day 4 ポリッシュ (Backlog #8 系) | 中 | 余裕があれば Day 3 後半 |
| 🥉 | Day 5 用 Issue 起票 (本番 credentials & master.key 配布) | 5 分 | Day 4 終了時に GitHub Issues に昇格 |
| 🥉 | `doc/development.md` に秘密管理方針セクション | 中 | Day 4 ポリッシュ枠 |

詳細と Day 1-2 の学び一覧は `memory/project_day3_kickoff.md` を参照。
