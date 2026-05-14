# CLAUDE.md

このファイルは Claude Code が weight_dialy プロジェクトで作業する際のガイダンスです。**毎セッション必ず読まれる前提** で、必要最小限に保つ (フリーライフ流の刈込原則)。

---

## 🚨 絶対ルール

### ⛔ main ブランチへの直接コミット禁止
**初回コミット以降のすべての作業は必ず作業ブランチで行う**。

#### 作業開始時の必須手順
1. `git branch` で main にいないことを確認
2. `git checkout main && git pull origin main` (リモートがあれば)
3. `git checkout -b <種別>/<内容>` (種別: `feature/`, `fix/`, `docs/`, `refactor/`)
4. ブランチで作業 → コミット → プッシュ → PR (`gh pr create --base main`)
5. マージ後、ブランチ削除

#### 二段構えのガード (実装済み)
- **Claude Code 側**: `.claude/hooks/block-main-push.sh` が PreToolUse hook で `git push ... main` をブロック
- **Git 側**: `.githooks/pre-push` が人間が直接打った場合も阻止
- **clone 直後の必須セットアップ**: `git config core.hooksPath .githooks` (bin/setup から自動設定)

---

## 📚 プロジェクト概要

**weight_dialy** は、通勤通学で歩く・階段を選ぶ等の **日常の小さな前向きな選択** を、スマホから自動で拾って褒めてくれる Web アプリ。

- **ターゲット**: ジムも筋トレもしない通勤通学カジュアル層
- **コンセプト**: 「日常の小さな勝ちを自動で拾って褒める」
- **公開**: スクールのミニアプリ発表会 (2026-05-06 19:00 締切)
- **教材性**: 後輩が API 連携 Web アプリのモデルケースとして読めることを意識

詳細スコープ・フェーズ計画は `memory/project_weight_dialy.md` を参照。

---

## 🛠️ 技術スタック (詳細は Gemfile / .ruby-version / .devcontainer/ を真とする)

| 項目 | 値 |
|---|---|
| Ruby | 3.4.9 |
| Rails | 8.1.3 |
| DB | PostgreSQL 16 (devcontainer 内) |
| フロント | Hotwire (Turbo + Stimulus) + Tailwind 4 + daisyUI |
| JS | Importmap (esbuild / webpack 不使用) |
| キャッシュ/ジョブ/ケーブル | Solid Cache / Solid Queue / Solid Cable (DB ベース) |
| 認証 | Google OAuth (予定: omniauth-google-oauth2) |
| データ取込 | Apple Shortcuts → Webhook (メイン) / デモモード / 手動 ZIP / Strava (余裕枠) |
| デプロイ | Kamal (or Render / Fly.io、Day 5 で確定) |
| テスト | RSpec + FactoryBot + Capybara/Cuprite (予定: Day 1 後半で導入) |
| Lint | rubocop-rails-omakase |
| 開発環境 | Dev Container (`.devcontainer/`) |

---

## 🤖 サブエージェント (`.claude/agents/`)

| エージェント | 役割 | フリーライフ対応 |
|---|---|---|
| `rails-implementer` | 実装担当 (Model/Controller/View/Service/Job) | 担当編集 |
| `test-writer` | RSpec / system spec 担当 | 担当編集 (テスト) |
| `code-reviewer` | コードレビュー (細部) | 編集長 |
| `strategic-reviewer` | 設計・スコープ・締切リスク・教材性レビュー (俯瞰) | 副局長 |
| `design-reviewer` | UI / UX / モバイル / コピーレビュー | (新設) |
| `api-researcher` | 外部 API・仕様調査 (実装はしない) | 外注 Gemini |

実装フローの基本: `api-researcher` (必要時) → `rails-implementer` → `test-writer` → 3 者並列レビュー (`code-reviewer` + `strategic-reviewer` + `design-reviewer`) → 局長 (ユーザー) 承認。

---

## 📁 主要ディレクトリ

- `app/` — Rails アプリ本体
- `config/` — Rails 設定 (`routes.rb`, `database.yml`, `deploy.yml` 等)
- `db/` — マイグレーション・スキーマ
- `spec/` — RSpec テスト (Day 1 後半に導入)
- `.devcontainer/` — Dev Container 設定
- `.claude/agents/` — サブエージェント定義
- `.claude/skills/` — 自動 invocation スキル (該当作業時のみ読込)
- `script/run` — **Dev Container 内でコマンドを実行するヘルパー** (`script/run "rails db:migrate"`)
- `memory/` (ホーム側) — 記憶ファイル (プロジェクト方針・ユーザー情報)

---

## 📝 コーディング規約

- Ruby は rubocop-rails-omakase に従う (`bundle exec rubocop`)
- Rails Way 優先。独自抽象を勝手に作らない
- fat model, skinny controller
- Service オブジェクト命名: 動詞+名詞 (`ImportStepDataService`)
- Hotwire ファースト (Turbo Frame / Stream / Stimulus)。SPA 化しない
- N+1 防止: `.includes` / `.preload` を意識

### 🎨 スタイル使い分けルール

- **コンポーネント**: `app/assets/stylesheets/sketchy.css` の `sketch-*` クラスを正とする
- **Tailwind utility**: `flex` / `grid` / `mt-4` / `container` 等のレイアウト用ユーティリティは引き続き使用 OK
- **daisyUI コンポーネント** (`btn` / `card` / `navbar` / `alert` 等): **新規利用禁止**。既存箇所も触ったタイミングで `sketch-*` に置換
- **危険度クラス**: `sketch-box-danger` / `sketch-h-danger` / `sketch-btn-danger` のように **独立クラス** (`sketch-*-danger`) で命名する (= modifier class `.sketch-box.filled` パターンとは別の体系。`-soft` 等の派生を組み合わせやすくするため)

---

## 📓 dev-log 運用フロー (= マージ後の必須作業)

PR をマージしたら、当日分の `docs/dev-log/day-N.md` にサマリー追記/作成する。

- **N の判定**: プロジェクト開始日 (= 2026-04-30) からの連番。例: day-7 = 2026-05-05
- **既存ファイルあり**: 該当セクション (= PR table / 起票/close した Issue / トラブル / 教訓 / 統計) に追記、数字も更新
- **既存ファイルなし**: 新規作成 (= day-1/2 のフォーマット踏襲、ヘッダ + リード + 🎯 目標 + ✅ 達成事項 + 🔥 トラブル + 🧠 教訓 + 📊 統計 + How to apply)
- **タイミング**: PR マージ**直後** (= 新鮮な記憶で書く方が情報量・正確性高、セッション終了時まとめだと忘れる)
- **commit ルール**: dev-log も main 直コミット禁止、別ブランチで PR → マージ (= 1 日 1 PR で `docs: day-N 開発ログ追加/更新` が筋)
- **適用範囲**: 機能・修正 PR が対象。Dependabot / typo 修正 / revert などの軽微 PR は省略可

教材性の継続的蓄積を目的とする (= Day 3-7 を後追いまとめ書きで踏んだ反省、詳細は memory `feedback_dev_log_after_merge.md` 参照)。

---

## 🔍 canon-check 標準手順 (= 設計判断前の自発検証)

設計判断の根拠 (= canon) を明示することで、将来の自分・後輩が判断経緯を追跡できるようにする手順 (= Issue #331 由来)。新機能提案・設計判断・memory 化判断など **大きな分岐点** に到達したら、ドラフト前に以下を実施する。

### 4 ステップ
1. 依拠する canon を 3-5 項目列挙 (= プロジェクト方針 / 規約 / memory 記載ルール)
2. 該当 memory ファイル名を明示引用
3. 矛盾チェック (= 列挙 canon と提案内容の衝突)
4. 衝突なし → ドラフト開始 / 衝突あり → ユーザーに相談

### 適用範囲
- ✅ 新機能・新画面の提案 (= 3 ステップ思想との整合性)
- ✅ UI 修正の方針決定 (= sketch-* / daisyUI 規約)
- ✅ memory 化判断 (= 3 回観測ルール / 自己提唱の相対化)
- ✅ 大きなリファクタの方針決定
- ❌ 軽微な typo 修正・コメント追記・テストのみ追加

### 出力フォーマット例

以下はフォーマット例であり、実際の検証表は各 PR / Issue 内で都度作成する。実運用例は Issue #331 参照。

| 依拠 canon | ソース | 矛盾 |
|---|---|---|
| 3 ステップ思想 (罪悪感 → 習慣化 → ガチ運動) | `project_weight_dialy_three_step_philosophy.md` | なし |
| sketch-* 採用 / daisyUI 新規禁止 | `CLAUDE.md` | なし |
| 3 回観測ルール (memory 化前) | `feedback_self_proposal_relativization.md` | 要注意: 現在 2 例目 |
| ジム連携機能の早期投入 | `project_weight_dialy_three_step_philosophy.md` | あり (= ③ ガチ運動段階を飛ばす) → ユーザー相談 |

衝突なしでも検証表を出すことで「canon を踏まえた判断であること」 を明示する (= 事後追跡可能)。詳細は memory `feedback_self_proposal_relativization.md` 参照。

---

## ⚠️ やってはいけないこと

- main 直コミット (上記絶対ルール)
- 過剰な抽象化 / DRY (3 回出てから抽象化)
- スコープ外のついでリファクタ (タスクで指示された範囲のみ)
- バックワード互換コード・未使用コードの放置
- セキュリティ上の手抜き (`raw`, `html_safe`, 文字列埋込 SQL, `skip_forgery_protection` 等)

---

## 🔗 関連ドキュメント

- `memory/MEMORY.md` — 記憶ファイルのインデックス (毎セッション自動読込)
- `memory/project_weight_dialy.md` — プロジェクト方針・フェーズ計画
- `memory/project_subagents.md` — サブエージェント設計詳細
- `.devcontainer/devcontainer.json` — 開発コンテナ仕様
