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

### 6 PR 完走

| PR | Issue | 内容 | コミット (squash 後) |
|---|---|---|---|
| #5 | #4 | main 直 push を阻止する二段構えガード | `cefe63c` |
| #7 | #6 | `/plan-issue` スラッシュコマンド | `17bbc97` |
| #10 | #9 | RSpec 導入 + /about TDD 教材サンプル | `ac5e76a` |
| #12 | #11 | Google OAuth (omniauth、Devise なし) | `1d2eccb` |
| #14 | #13 | ホームダミー除去 + 仮ログイン UI 正規化 | `68f51bf` |
| #16 | #15 | フラッシュ自動非表示 Stimulus | `0edcf45` |

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

### Day 1-2 全体で完走した PR (リポジトリ通算)

- Day 1: PR #1, #3
- Day 2: PR #5, #7, #10, #12, #14, #16

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
- **重要箇所 (セキュリティ系・アクセシビリティ系) は再レビュー必須** (PR #12, #14, #16 で実証)
- **回帰防止 spec で「設計上禁止したいもの」を `not_to include` で明示** すると、設計意図のドキュメント化になる (PR #14 の Primary/Secondary/Accent 否定アサーション)

### ツール導入の判断軸
- **プラグイン / gem / ツール導入時は現在の技術スタック相性を最優先軸とする** (Hotwire ベース Rails に React 前提の Anthropic 公式 `frontend-design` プラグインは不適合と判断)

---

## 📌 Day 3 への積み残し

| 優先 | タスク | 工数 |
|---|---|---|
| 🥇 | Rails `credentials.yml.enc` への移行 (Day 5 のデプロイ前に先取り) | 30 分 |
| 🥈 | Apple Shortcuts → Webhook 受信 (要 `api-researcher` の WebSearch / WebFetch 権限) | 大 |
| 🥉 | Day 4 ポリッシュ (Backlog #8 系) | 中 |

詳細と Day 1-2 の学び一覧は `memory/project_day3_kickoff.md` を参照。
