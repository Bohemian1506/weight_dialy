---
description: code-reviewer / strategic-reviewer / design-reviewer の 3 者並列レビューを 1 メッセージ内で起動する。Agent 別 + 末尾統合サマリで提示。
argument-hint: [PR 番号 | 観点キーワード (省略可、省略時は現在ブランチの diff)]
---

# /review-three

PR ごとに 3 者並列レビュー (= code/strategic/design) を起動するコマンド。
memory `feedback_always_three_reviewers.md` の「PR 規模に関わらず必ず通す」ルールを機械化 (= Issue #259)。

## 入力

対象: $ARGUMENTS

- **空**: 現在のブランチ diff (`git diff main..HEAD`) を対象
- **整数のみ** (例: `255`): PR 番号として扱う (= `gh pr view 255`)
- **その他文字列** (例: `security` / `mobile` / `scope`): 重点観点として 3 Agent に伝える

## フロー

### Step 1: 対象範囲を確定

引数を以下のいずれかに振り分ける:

```bash
# 空 or 観点キーワード → 現在のブランチを対象
git rev-parse --abbrev-ref HEAD
git diff main..HEAD --stat
git log main..HEAD --oneline

# 整数 (PR 番号) → PR を対象
gh pr view <N> --json title,body,files,headRefName,additions,deletions
gh pr diff <N> --name-only
```

ブランチ名や PR title から **関連 Issue 番号** を抽出 (例: `feature/review-three-command` → Issue #259、コミットメッセージの `(#NNN)` パターン)。抽出できなければ「関連 Issue 不明」 で進めて OK。

### Step 2: 3 Agent を **1 メッセージ内で並列起動**

**重要**: Agent tool call を **1 つの assistant メッセージ内に 3 つ並べて** 同時実行する (= 直列起動禁止、コスト効率と時間効率のため)。

各 Agent に渡す共通 context:

```
PR 番号 / ブランチ名: <Step 1 で取得>
変更範囲: <ファイル数 / 追加・削除行数>
変更ファイル一覧: <files>
関連 Issue: #<番号> (= 抽出できた場合のみ)
重点観点: <引数の観点キーワード or "なし">
プロジェクト背景: weight_dialy (= memory `project_weight_dialy.md` 参照、CLAUDE.md 既読前提)
```

各 Agent への個別指示:

- **code-reviewer**: 「diff レベルの細部 (構文 / 命名 / セキュリティ / Rails 慣習 / N+1 / 例外処理) をレビュー。出力は 🚨 Blocker / ⚠️ Should fix / 💡 Nit + 総合判定 (✅/🟡/❌)」
- **strategic-reviewer**: 「俯瞰視点 (設計判断 / スコープ / MVP 過剰 / 教材性 / 将来拡張) をレビュー。出力は判定 (🟢/🟡/🔴) + 論点 1〜3 個 + 学びポイント」
- **design-reviewer**: 「UI 変更がある場合のみ実施。視認性 / モバイル / 情報設計 / コピー / オンボーディングをレビュー。出力は総合判定 (🟢/🟡/🔴) + カテゴリ別指摘 + デモ向上提案」
  - UI 変更ゼロの PR (= バックエンドのみ / Skill / Command 新設) では起動するが「UI 変更なし、観点ヒットなし」 と返ってくる前提で OK

### Step 3: Agent 別セクションで結果を提示

3 Agent の出力を **そのままのフォーマットで** 並べる (= 各 Agent の判定軸 / 教材性を保持):

```markdown
## 🔍 code-reviewer

(code-reviewer の生出力。🚨/⚠️/💡 + 総合判定をそのまま転載)

## 🎯 strategic-reviewer

(strategic-reviewer の生出力。🟢/🟡/🔴 + 論点 + 学びポイントをそのまま転載)

## 🎨 design-reviewer

(design-reviewer の生出力。UI 変更なしなら「観点ヒットなし」 で 1 行)
```

### Step 4: 末尾に統合サマリを再分類

3 Agent の指摘を **🚨 Blocker / 🟡 軽微 / 🟢 提案** の 3 段階に Command 側で再分類して提示。

#### 再分類マッピング

| Agent 元の表記 | 統合分類 |
|---|---|
| code: 🚨 Blocker | 🚨 Blocker |
| strategic: 🔴 スコープ切り直し | 🚨 Blocker |
| design: 🔴 デモに出せない | 🚨 Blocker |
| code: ⚠️ Should fix | 🟡 軽微 |
| strategic: 🟡 設計見直し | 🟡 軽微 |
| design: 🟡 修正後 OK | 🟡 軽微 |
| code: 💡 Nit | 🟢 提案 |
| strategic / design の追加アイデア・将来送り提案 | 🟢 提案 |

#### 統合サマリ出力フォーマット

```markdown
---

## 📊 統合サマリ (= /review-three 再分類)

🚨 Blocker (N)
- [code] <内容> (file:line)
- [design] <内容>

🟡 軽微 (M)
- [strategic] <内容>
- [code] <内容> (file:line)

🟢 提案 (K)
- [strategic] <内容>
- [code] <内容> (file:line)

総合判定: <🚨 Blocker あり = マージ前修正必須 / 🟡 のみ = 修正推奨 / 🟢 のみ = approve OK>
```

## 引数別の挙動例

### 引数なし (= 現在ブランチを対象)

```
/review-three
→ git diff main..HEAD を 3 Agent に渡す
→ 重点観点: なし
```

### PR 番号指定

```
/review-three 255
→ gh pr view 255 で範囲取得
→ 重点観点: なし
```

### 観点キーワード指定 (= 現在ブランチ + 重点観点)

```
/review-three security
→ git diff main..HEAD を対象 (= 引数なしと同じ)
→ 重点観点: security (= 各 Agent に明示的に伝える)
```

### PR 番号 + 観点 (= スペース区切り、両方渡す)

```
/review-three 255 security
→ PR 255 を対象、重点観点: security
```

引数解釈の優先順位:
1. 1 トークン目が整数 → PR 番号
2. 残りトークン (or 全トークン) → 観点キーワードとして連結

## 注意事項

- **3 Agent 並列起動が必須** (= 直列起動はコスト・時間で損)。1 メッセージに 3 つの Agent tool call を並べる
- **Agent はファイル編集しない** (= Read/Bash/Grep のみ)、指摘を受けて Claude 本体が修正コミットを作る
- **再レビュー時** は修正コミット SHA + 反映ロジックを Agent に渡す (= 各 Agent の依頼例参照)
- **軽微 PR (= Dependabot / typo / spec 数値更新のみ) で発火させたくない場面** はユーザー判断、本 Command は明示打ち専用 (= Skill 自動発火しない)
- レビュー実行はコスト高 (= 3 Agent 並列で大量 token)、無闇に連発しない

## 関連

- memory `feedback_always_three_reviewers.md` (= 機械化元、3 者並列必須ルール)
- memory `project_plan_issue_skill_consideration.md` (= Command vs Skill の判断軸)
- `.claude/agents/code-reviewer.md` / `strategic-reviewer.md` / `design-reviewer.md` (= 起動対象、出力フォーマット定義元)
- Issue #259 (= 本 Command 起源)
- 関連 Issue (= Day 9-3 着手 4 連発): `/plan-issue` (#256) / `/dev-log-merge` (#257) / `/mode` (#258)
