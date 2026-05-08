---
name: dev-log-merge
description: PR マージ直後に当日分 docs/dev-log/day-N.md の追記または新規作成を機械化する。コマンド観測 + 発言観測で自動発火、対話で材料引き出し + 数字 3 箇所同期 + ブランチ切り PR 作成まで一気通貫。軽微 PR や dev-log 自身の PR では発火しない。
---

# Skill: dev-log-merge

memory `feedback_dev_log_after_merge.md` で確立した「PR マージ直後に `docs/dev-log/day-N.md` に追記/新規作成」 運用を機械化する Skill。9 日間で 30+ 回手作業した同じ判定 → 追記サイクルを Skill 自動発火で吸収する (= Issue #257)。

## 設計思想

- **自動発火**: 漏らしたら困る度高、発火条件明確、止めたい場面少 (= memory `project_claude_tooling_roadmap.md` の使い分け軸)
- **対話で材料引き出し + Claude 文章化**: 局長判断 + 機械化を両立 (= 完全自動だと嘘ログ化、完全手動だと機械化 ROI 消失)
- **数字 3 箇所同期は候補値提示 + 編集前確認**: memory `feedback_dev_log_after_merge.md` の核心ルール、9 日間で同期漏れ実績ありの最重要箇所
- **誤発火吸収**: 起動時確認スピンで「対象 PR は #X で OK?」 を必ず聞く

## 発火条件 (= 自動)

以下のいずれかを観測したら起動:

1. **マージコマンド実行直後**: `gh pr merge --squash --delete-branch` 等のコマンドが実行された
2. **局長発言**:
   - 「マージしました」「マージ完了」「#X マージした」
   - 「PR #X 完了」「PR #X 着地」
   - GitHub Web UI でマージした旨の報告 (= 「Web からマージしたよ」)

## 発火させない場面 (= 明示)

- **dev-log 自身の追記 PR** (= 無限ループ防止、PR title が `docs: day-N` で始まる)
- **軽微 PR** (= PR title から自動判定):
  - `dependabot/...` 由来
  - `fix: typo` 系
  - `revert:` 系
  - `chore(deps):` 系
- **局長が「dev-log 不要」 と明示した直後**
- **既に当該 PR の dev-log 追記が完了済** (= 同じ PR を再追記しない)

## 実行フロー

### Step 1: 起動時確認スピン

```
PR #X (= title) のマージを観測しました。day-N.md に追記しますか?
- Y: 追記モードへ
- N: 停止 (= 軽微 PR と判定 / 局長判断で見送り)
- skip-this-time: 今回のみスキップ (= 後で手動追記する)
```

ユーザー Y で Step 2 へ、N / skip で停止。

### Step 2: N 候補値の算出 + 局長判断

N は **カレンダー日連番ではなく、運用上のセッション日番号** (= memory `feedback_dev_log_after_merge.md` 参照、day-4/day-5 = 同日 5/3 分割の歴史的事例あり)。Skill は機械的に決めず、**最新ファイル + 今日の日付を局長に提示して判断を仰ぐ**。

#### 算出ロジック

1. `ls docs/dev-log/day-*.md | sort -V` で全ファイル取得
2. 最新ファイル名から N を抽出 (= 例: `day-9-3.md` → N=9)
3. 今日の日付を取得 (= `date +%Y-%m-%d`)
4. 局長判断を仰ぐ:

```
最新 dev-log: docs/dev-log/day-9-3.md (= 2026-05-07 由来)
今日: 2026-05-08

N をどうしますか?
- new: 新規 N (= day-10) で開始
- same: 同じ N (= day-9) で続行 (= 既存最新の day-9-3.md に追記 or 新規分割で day-9-4.md)
- N=X: 明示で N を指定 (= 例: 「N=11」 で day-11 開始)
```

→ 局長応答で `target_N` 確定 → Step 3 へ。

### Step 3: 既存ファイル判定 (= A-2 ロジック)

`target_N` 確定後、`ls docs/dev-log/day-${target_N}*.md` で全マッチ確認:

| 状態 | 動作 |
|---|---|
| ファイル無し | **新規モード** へ (= Step 4-A) |
| `day-N.md` のみ存在 | **既存追記モード** (= Step 4-B)、対象ファイル = `day-N.md` |
| `day-N-1.md` / `day-N-2.md` ... 存在 | **既存追記モード**、対象 = **最新の連番ファイル** (= 例: `day-N-3.md` があれば `day-N-3.md`) |

### Step 3-1: 分割切り出し判定

局長発言で以下のキーワードを観測したら **新規分割モード** に切り替え (= 既存追記でなく新ファイル作成):

- 「新セッション」「新ファイル切り出し」「day-N-X+1.md として」「新セッションで」
- 「セッション分ける」「ここから別ファイル」

→ 既存最新が `day-N-3.md` なら `day-N-4.md` を新規作成。
→ 既存が `day-N.md` (= 単一) で局長が「分割」 宣言したら **`day-N.md` はそのままで `day-N-2.md` を新規作成** する (= 既存リネームは混乱要素なので避ける)。
→ 局長が **休日など長時間作業のときに都度宣言する** 運用 (= 局長運用ルール、本 Skill は宣言を観測する側)。

### Step 4-A: 新規モード (= スケルトン生成 + 対話)

day-1/2 のフォーマット踏襲でスケルトンを提示し、空欄部分を **対話で材料引き出し → Claude が本文組み立て**。

#### 対話フロー

```
day-${N}.md を新規作成します。スケルトン作るので材料いくつか教えてください。

Q1. サブタイトル / 戦略テーマ (= 1-2 文で。例: "MVP 後 polish 初日")
Q2. 今日マージした PR と要点 (= PR# + Issue# + 1 行内容)
Q3. 教訓・学び (= 番号 + 一言、なければスキップ)
Q4. How to apply に残す運用パターン (= なければスキップ)
Q5. 残タスク (= なければスキップ)
```

#### スケルトン構造 (= 空欄を対話で埋める)

```markdown
# Day ${N} 開発ログ (${YYYY-MM-DD}、${サブタイトル})

${リード文 = 「N PR マージ + N 起票 + N close + 学び X 確立」 形式}

## 🎯 Day ${N} の目標
1. ${目標 1}
2. ${目標 2}

## 🏆 達成したこと

### マージ済み PR (= ${N} 本)
| PR | Issue | 内容 |
|---|---|---|
| #${PR} | #${Issue} | ${内容} |

### close した Issue (= ${N} 件)
- **#${Issue}** (= ${概要}) — PR #${PR} で close

## 🧠 教訓ハイライト (= ${N} 件、本日確立)
### 学び ${X}: ${タイトル}
${本文}

## 📊 統計
- マージした PR: ${N} 本
- close した Issue: ${N} 件
- 起票した Issue: ${N} 件
- spec: ${X} examples
- rubocop: ${X} offenses
- 教訓: ${N} 件

## 🎯 残タスク
- [ ] ${タスク 1}

## How to apply
${運用パターン}
```

→ Claude が本文組み立て → 局長レビュー → Step 6 へ。

### Step 4-B: 既存追記モード

#### 数字 3 箇所同期チェック (= D-2 + 派生)

`grep -n` で現状値を抽出し、+1 した候補値を提示:

```
🔢 数字同期チェック (= memory feedback_dev_log_after_merge.md 核心ルール)

現状値の grep 結果:
- リード文 (line ${X}): "${現在のリード文}"
- セクションヘッダ:
  - line ${X}: "### マージ済み PR (= ${N} 本)"
  - line ${X}: "### close した Issue (= ${N} 件)"
  - line ${X}: "### 起票した Issue (= ${N} 件)"  ← 該当時のみ
- 統計 (line ${X}-${Y}):
  - マージした PR: ${N} 本
  - close した Issue: ${N} 件
  - 起票した Issue: ${N} 件
  - spec: ${X} examples
  - 教訓: ${N} 件

候補値 (= 今 PR を +1 した結果):
- リード文: "${候補リード文}"
- セクションヘッダ: "### マージ済み PR (= ${N+1} 本)" 等
- 統計: マージ PR: ${N+1} / close Issue: ${N+1} (= +1 想定)

🟡 注意: 以下は局長判断必要 (= PR 由来の数字)
- spec examples 数 (= 今 PR で変化した?)
- rubocop offenses 数
- 学び番号 (= 今 PR で確立した?)
- 起票した Issue 数 (= 今 PR で起票した?)

→ 確認: 上記候補で edit してよいですか?
  Y: 全候補値で edit 実行
  edit-spec=612 edit-学び=36: 差分のみ修正
  N: 中止
```

#### 派生同期チェック (= D-2 派生)

学び番号 / 達成見出しも同様に grep:

- **🏆 達成したこと の見出し文字列**: `## 🏆 達成したこと (= PR #X + #Y マージ + Issue close + 学び 確立)` → 今 PR の番号を追記
- **学び番号**: リード文の「学び X 確立」 と教訓セクションのヘッダ番号 `### 学び X:` が同期しているか確認、新規学びがあれば候補値 +1 提示

#### 対話フロー (= 既存追記)

```
day-${N}-Y.md (= 既存) に PR #X 追記します。

Q1. PR の要点 (= 1 行内容、PR table 行に入れる)
Q2. close した Issue の概要 (= close Issue list 行に入れる)
Q3. 教訓・学び 追加? (= なければスキップ、あれば番号 + 一言)
Q4. 統計に追加すべき指標? (= spec 数変化 / rubocop 等、なければスキップ)
```

→ Claude が PR table 1 行 + close Issue list 1 行を整形 → Step 6 へ。

### Step 5: 本文組み立て + 局長レビュー

新規モード = スケルトン全文を提示、既存追記モード = 差分 (= 追加行 + 数字 edit) を提示。

```
本文プレビュー:
---
${生成された markdown}
---

→ この内容で edit 実行しますか?
  Y: edit 実行 → Step 6 へ
  edit-section: ${特定セクション} を局長コメント反映して再生成
  N: 中止
```

### Step 6: ブランチ切り + commit + push + PR 作成

main 直コミット禁止 (= CLAUDE.md 絶対ルール)。以下を順次実行:

```bash
# 1. main から作業ブランチ切り
git checkout main
git pull origin main
git checkout -b docs/day-${N}-update-${PR番号}

# 2. ファイル編集 (= Edit / Write tool)
# 3. commit (= main 直禁止、現ブランチで)
git add docs/dev-log/day-${N}${サフィックス}.md
git commit -m "docs: day-${N} に PR #${PR番号} 反映"

# 4. push + PR 作成
git push -u origin docs/day-${N}-update-${PR番号}
gh pr create --title "docs: day-${N} 開発ログ追加/更新 (= PR #${PR番号} 反映)" \
  --body-file <(cat <<'EOF'
## Summary
- PR #${PR番号} (= ${PR title}) を day-${N}${サフィックス}.md に反映
- 数字 3 箇所同期更新 (= リード文 / セクションヘッダ / 統計)

## Test plan
- [ ] 数字 3 箇所が同期している (= grep 確認)
- [ ] 後輩が読んで価値ある内容になっている

🤖 Generated with [Claude Code](https://claude.com/claude-code)
EOF
)
```

PR URL を表示して終了。3 者並列レビューは局長判断 (= dev-log は教材性 PR、軽量レビューで OK な場合あり)。

## ブランチ命名

`docs/day-${N}-update-${PR番号}` 形式 (= memory `feedback_dev_log_after_merge.md` の commit ルール踏襲)。

## アンチパターン

- **完全自動 edit (= D-1 級)**: 嘘ログ化、PR 由来数字 (spec / 学び番号) を Skill が勝手に推測してはいけない
- **発火しなかったケースを放置**: 局長発言観測の漏れに気付いたら、その場で「dev-log 追記しますか?」 と提案する (= memory `feedback_dev_log_after_merge.md` の「マージ → dev-log → 次のタスク」 サイクル維持)
- **dev-log 追記 PR を main 直コミット**: 絶対禁止、必ず作業ブランチで PR
- **学び番号の重複**: 既存 dev-log の学び X が最新かを確認せず +1 すると番号衝突。Step 4-B の派生同期チェックで grep 必須

## 関連

- Issue #257 (= 本 Skill 新設の起源、Claude tooling 第一群 4 連発の 2 番目)
- memory `feedback_dev_log_after_merge.md` (= 機械化元の運用ルール、3 箇所同期核心ルール元)
- memory `project_claude_tooling_roadmap.md` (= 第一群 4 連発の位置付け、Skill 自動の使い分け軸)
- CLAUDE.md「📓 dev-log 運用フロー」 セクション (= 整合確認元)
- 過去 dev-log: `docs/dev-log/day-1.md` 〜 最新 (= テンプレ参照元、新規モードのフォーマット参考)
- Skill `propose-issue` (= 同じく Day 9-3 で第一群 1 番目として整備、二段構え提案型 / 本 Skill = 自動発火型 の対比例)
