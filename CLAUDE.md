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
