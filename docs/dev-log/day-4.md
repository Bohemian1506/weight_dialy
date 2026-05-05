# Day 4 開発ログ (2026-05-03 前半)

GW 4 日目の前半。Day 3 で完成した Rails 側の Webhook 受信エンドポイント (PR #31) を **iPhone 実機からテストする** ための環境整備に費やした半日。具体的には **VS Code Dev Container + WSL2 + ngrok** という三層構造を成立させる Docker Compose 設定を整え、`Rails.application.config.hosts` に ngrok のドメインを許可する PR #44 を完走。1 PR と少ないが、その背景には「Windows + WSL2 + devcontainer の境界線」を理解する深い学びがあった。**夜の 5 時間死闘 (= Authorization 末尾空白事故) は別 dev-log (day-5.md) に独立記録**。

---

## 🎯 Day 4 前半の目標

1. iPhone 実機テストの前提条件 (= Phase 2 = `Issue #35`) を整備する
2. ngrok 経由で WSL2 host から container 内 Rails に届く経路を確立
3. `Rails.application.config.hosts` に ngrok のサブドメインを正しく許可
4. Day 3 で OPEN だった PR #32-#34 のマージ確認

---

## ✅ 達成事項

### PR #44 完走: dev container で WSL2 host に 3000 を publish + ngrok ホストを許可

| 項目 | 内容 |
|---|---|
| `docker-compose.yml` | Rails container の 3000 を `0.0.0.0` (= WSL2 host) に直接 publish |
| `config/environments/development.rb` | `Rails.application.config.hosts << /\.ngrok-free\.(app|dev)\z/` で ngrok 両ドメインを許可 |
| `memory/project_apple_shortcuts_webhook_research.md` | 「ngrok 2 ドメイン体系」をハマりポイント 6 件目として追記 |

### Issue #45 起票 (Backlog): mise trust 自動化

container を recreate すると `mise trust` 状態が消えて Ruby/bundle/rails 全部ブロックされる問題を、`postCreateCommand` で `mise trust /workspaces/weight_dialy/mise.toml` を自動実行する形で解消する案。Backlog に積んで発表会後対応とした (= 3 回踏むまで早すぎる抽象化を避ける Rule of Three を尊重)。

### Day 3 の OPEN PR 3 件マージ完了

`#32` (README) → `#33` (Settings) → `#34` (Dashboard) の順でマージ。順序は **#33 を先にマージしないと #34 の banner リンクが 404** になるという PR description の警告通り。

---

## 🔥 遭遇したトラブルと解決

### トラブル 1: VS Code Dev Container `forwardPorts` の限界

**症状**: WSL2 host から `curl http://localhost:3000` しても Rails に届かない。`devcontainer.json` の `forwardPorts: [3000]` を信じて 3000 を発見しようとしたが空振り。

**真因**: Windows VS Code → WSL2 → devcontainer の構成では、`forwardPorts` の forward 先は **Windows host** で、**WSL2 host ではない**。WSL2 上の外部プロセス (= ngrok 等) から container 内 Rails に届かせるには、別経路が必要。

**解決**: `docker-compose.yml` の `ports` 指定で host (= WSL2) に直接 publish:

```yaml
services:
  rails:
    ports:
      - "0.0.0.0:3000:3000"
```

これで WSL2 host の `0.0.0.0:3000` から container 内 Rails の 3000 にトンネルが通り、ngrok もそこに刺さる。

**教訓**: **`forwardPorts` は VS Code (= Windows host) の便宜のための機能**。container 外の他プロセスとの通信を想定するなら Docker Compose の `ports` が正解。

### トラブル 2: ngrok 無料プランは 2 ドメイン体系

**症状**: 朝確認した時は `*.ngrok-free.app` だったが、午後の再起動で `*.ngrok-free.dev` に変わっていた。`Rails.application.config.hosts << /\.ngrok-free\.app\z/` だけでは新ドメインが「Blocked host」403 になる。

**真因**: ngrok 無料プランは **`*.ngrok-free.app` と `*.ngrok-free.dev` の両方が運用されている**。配布タイミングや時間帯によって振り分けが変わる (= ngrok のロードバランサ判断)。

**解決**: 正規表現で両ドメイン許可:

```ruby
# config/environments/development.rb
Rails.application.config.hosts << /\.ngrok-free\.(app|dev)\z/
```

**教訓**: **ngrok のドメイン体系は実機運用で踏むまで分からない**。memory `project_apple_shortcuts_webhook_research.md` のハマりポイント 6 件目として永続化し、後輩教材化。

### トラブル 3: `config.hosts << Regexp` の内側に `\A`/`\z` 不要

**症状**: 当初 `Rails.application.config.hosts << /\A.+\.ngrok-free\.(app|dev)\z/` のように外側 `\A`/`\z` を入れて書いた。code-reviewer が「`actionpack-8.1.3` の `Permissions#sanitize_regexp` (= `actionpack/lib/action_dispatch/middleware/host_authorization.rb:71-73`) が内部で `/\A...#{PORT_REGEX}?\z/` をラップする実装」とソース実引用で指摘。

**真因**: 内側に `\A`/`\z` を書くと、port 付き host (= `abc.ngrok-free.dev:443`) で誤動作する。Rails が外側でラップする前提なので、配列に渡す Regexp は **bare な部分一致パターン** で十分。

**解決**: 外側 `\A`/`\z` を削除し、`/\.ngrok-free\.(app|dev)\z/` の形に。

**教訓**: **「ソース引用 > 推測」**。今回の code-reviewer の判断は actionpack のソースを実引用した実証ベース。これに対して別 reviewer (= 生 Regexp で誤判定しかけたケース) の推測ベース判断と比較して、真値到達速度が段違い。

### トラブル 4: `mise` の trust は container 単位で消える

**症状**: container を recreate した後、`bundle install` も `bin/rails` も「mise: untrusted file」エラーで全部ブロック。

**真因**: `mise` の trust 状態は `~/.local/share/mise/trusted-configs/` 相当に保存されるが、container を recreate するとこのディレクトリも初期化される。

**解決**: 手動復旧 `mise trust /workspaces/weight_dialy/mise.toml`。Backlog Issue #45 で `postCreateCommand` 自動化案を起票 (= 発表会後対応)。

**教訓**: container ライフサイクルで消える設定は **`postCreateCommand` でブートストラップする** のが正解。今回は手動運用 + 自動化 Issue で十分 (= 1 日の中で 3 回踏むまで自動化しない Rule of Three)。

### トラブル 5: `Procfile.dev` に外部ツール統合は工数大

**仮説**: `bin/dev` (= foreman) で Rails dev server と ngrok を 1 コマンド化すれば運用ラク。

**結論 (見送り)**: foreman は実行環境 (= container / host) を跨げないため、container 内 Rails と host 側 ngrok を 1 コマンドで起動するには **Dockerfile 編集 + ngrok authtoken の受け渡し設計** まで必要。MVP として工数 > 利得。

**教訓**: **3 回ルール (= Rule of Three) に達するまで手動運用**を選ぶ。早すぎる抽象化を避ける経験則として強く意識した判断。

---

## 🧠 学習ポイント (= Rails 初学者ユーザー向けに対話で深掘り)

### 「`bin/dev` (= foreman) は片方の世界しか見えない」 — container と host の境界

VS Code → WSL2 → devcontainer という三層構造では、各層が独立した「世界」。各層から見える物・見えない物を理解しないと、一見シンプルな「外部から localhost:3000 に届かない」問題で延々ハマる。

| 層 | 見える | 見えない |
|---|---|---|
| Windows VS Code | container 内 (= forwardPorts 経由) | WSL2 host のプロセス、container の物理 port |
| WSL2 host | container の `ports` で publish された port、ngrok 等の自身のプロセス | container 内のファイルシステム |
| container 内 | 自身の Rails / DB | 外部のプロセス、ngrok |

→ 今回必要だったのは **「WSL2 host から container 内 Rails への経路」**。これは `docker-compose.yml` の `ports` で確立する以外の方法がない (= forwardPorts は Windows host 向け)。

### 「3 回ルール (= Rule of Three)」 — 早すぎる抽象化を避ける経験則

DRY を「3 回出てから抽象化する」と読み替える経験則。今回の `Procfile.dev` 統合判断はこの典型例:

- 1 回目: 手動で起動 → 動く、これは仕方ない
- 2 回目: 「何度もやるな」と思う → でもまだ抽象化しない
- 3 回目: 同じパターンが見えた → 初めて抽象化する

**理由**: 抽象化を剥がすコスト > 重複を許容するコスト。早すぎる抽象化は「不適切な抽象化」になりやすい (= 後で別パターンが出てきた時、抽象が適合しなくなって剥がす羽目になる)。

今回は手動運用 + Backlog Issue #45 起票で十分 (= 自動化が必要になる時点でまた検討する)。

### 「ngrok のライフサイクル = Rails dev server とほぼ同じ」

ngrok は本番デプロイ後は不要。**install は 1 度、起動は都度、production デプロイ完了で破棄**。Rails dev server (`bin/rails s`) と同じ「開発時のみ必要」道具として理解すると、運用イメージがつかみやすい。

→ Day 5 (= 5/4) で Render に本番デプロイした後は、ngrok は使わなくなる予定 (= 本番 URL が固定されるため、Apple Shortcuts は本番 URL を直接叩く)。

---

## 🎯 Day 4 前半の戦略的気付き

### 1. 環境整備に半日かかるのは普通

- iPhone 実機テストの前提整備 (= ngrok + Rails hosts 許可) で半日
- 「実機 200 OK」までの道のりは **コードよりも環境設定の方が長い**
- 慌てず、各層の境界を理解しながら進める

### 2. ソース引用の威力

- `Rails.application.config.hosts` の正規表現で `\A`/`\z` をどこに置くか判断する時、actionpack のソース (`host_authorization.rb:71-73`) を直接読んだ code-reviewer の判断が正確
- 推測ベースの reviewer (= 生 Regexp で誤判定しかけたケース) との比較で **「ソース引用 > 推測」** が再確認された
- 今後の運用ルール: 微妙な挙動が問題になる時は **gem ソースを直接 grep する**

### 3. Backlog Issue による「やらない」の可視化

- mise trust 自動化、Procfile.dev 統合は **Issue #45 で Backlog 化**
- 「やりたいけど今やらない」を可視化することで、scope 拡大の罠を避けられる

---

## 📊 統計

- マージした PR: **1 本** (= #44)
- マージ確定した PR (= Day 3 由来): **3 本** (#32, #33, #34)
- 起票した Issue: 1 件 (= #45 Backlog)
- 全体 spec: 210 → 210 examples (= 環境整備のみ)
- 学んだ知見: 5 件 (= forwardPorts / ngrok 2 ドメイン / Regexp `\A`/`\z` / mise trust / Procfile.dev 統合工数)

---

## How to apply

- **Day 5 (= 翌日 5/3 夜、別 dev-log)**: iPhone 実機 (= iPad) で Apple Shortcuts を組んで POST → 200 OK + step_records 記録確認
- **「外部から localhost:3000 に届かない」が出たら**:
  - VS Code → WSL2 → devcontainer の三層構造を思い出す
  - `forwardPorts` (= Windows VS Code 向け) と `docker-compose ports` (= WSL2 host 向け) を区別する
- **`Rails.application.config.hosts` で Regexp を使う時**:
  - 内側に `\A`/`\z` を書かない (= actionpack が外側でラップ)
  - 部分一致パターンで十分
- **環境整備に半日以上かかった時**:
  - 抽象化に走る前に、まず手動運用で 3 回踏む (= Rule of Three)
  - Backlog Issue で「やらない」を可視化
