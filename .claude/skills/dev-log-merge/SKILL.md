---
name: dev-log-merge
description: PR マージ直後に当日分 docs/dev-log/day-N.md の追記または新規作成を機械化する。コマンド観測 + 発言観測で自動発火、対話で材料引き出し + 数字 3 箇所同期 + ブランチ切り PR 作成まで一気通貫。軽微 PR や dev-log 自身の PR では発火しない。
---

# Skill: dev-log-merge

memory `feedback_dev_log_after_merge.md` で確立した「PR マージ直後に `docs/dev-log/day-N.md` に追記/新規作成」 運用を機械化する Skill。9 日間で 30+ 回手作業した同じ判定 → 追記サイクルを Skill 自動発火で吸収する (= Issue #257)。

## 設計思想

- **自動発火を選んだ理由**: 「漏らしたら困る + 発火条件明確 + 止めたい場面少」 の 3 条件揃い (cf. `propose-issue` = 提案型 / `/review-three` = 明示) — memory `project_claude_tooling_roadmap.md` の Skill / Command 使い分け軸
- **対話で材料引き出し + Claude 文章化**: 局長判断 + 機械化を両立 (= 完全自動だと嘘ログ化、完全手動だと機械化 ROI 消失)
- **数字 3 箇所同期は候補値提示 + 編集前確認**: memory `feedback_dev_log_after_merge.md` の核心ルール、9 日間で同期漏れ実績ありの最重要箇所
- **誤発火吸収**: 起動時確認スピンで「対象 PR は #X で OK?」 を必ず聞く
- **「実演後判断」 適用 v0**: 1 周も発火していない仕様の先回りを排除 (= Step 3-1 分割切り出し判定 / 派生同期 = 学び番号 + 達成見出し は v0 で削除、Day 10 以降の実運用観察後に必要なら別 PR で追加)

## 発火条件 (= 自動)

以下のいずれかを観測したら起動 (= **現在進行・直近のマージに限定**):

1. **マージコマンド実行直後**: `gh pr merge --squash --delete-branch` 等のコマンドが実行された
2. **局長発言** (= 直近のマージ報告に限る):
   - 「マージしました」「マージ完了」「#X マージした」
   - 「PR #X 完了」「PR #X 着地」
   - GitHub Web UI でマージした旨の報告 (= 「Web からマージしたよ」)

## 発火させない場面 (= 明示)

- **dev-log 自身の追記 PR** (= 無限ループ防止、PR title が `docs: day-` プレフィックスで始まる、`day-9-3` 等の分割番号にも対応)
- **軽微 PR** (= PR title から自動判定):
  - `dependabot/...` 由来
  - `fix: typo` 系
  - `revert:` 系
  - `chore(deps):` 系
- **過去 PR の回顧・言及** (= 「先週マージした #X は...」「あの時の #Y どう思う?」 等の回顧形式) — 直近マージ報告と区別
- **局長が「dev-log 不要」 と明示した直後**
- **既に当該 PR の dev-log 追記が完了済** (= 同じ PR を再追記しない、Step 1 の前に対象ファイルを `grep "#${PR番号}"` で確認)

## 実行フロー

### Step 1: 起動時確認スピン (= 所要時間目安: 5 問答で約 3 分)

```
PR #X (= title) のマージを観測しました。day-N.md に追記しますか?
- Y: 追記モードへ
- N: この PR は追記しない (= 次の PR でも発火する)
- skip-this-time: 今回のみスキップ、後で手動追記 (= このセッション中は再提案しない)
```

ユーザー Y で Step 2 へ、N / skip で停止。

### Step 2: N 候補値の算出 + 局長判断

N は **カレンダー日連番ではなく、運用上のセッション日番号** (= memory `feedback_dev_log_after_merge.md` 参照、day-4/day-5 = 同日 5/3 分割の歴史的事例あり)。Skill は機械的に決めず、**最新ファイル + 今日の日付を局長に提示して判断を仰ぐ**。

#### 算出ロジック

1. `ls docs/dev-log/day-*.md | sort -V` で全ファイル取得、最新ファイル名から N を抽出 (= 例: `day-9-3.md` → N=9)
2. 最新ファイルの先頭行から日付を grep で抽出 (= `grep -m1 "^# Day" <file>` → 「`# Day 9-3 開発ログ (2026-05-07 ...)`」 から `2026-05-07` を取得)
3. 今日の日付を取得 (= `date +%Y-%m-%d`)
4. 局長判断を仰ぐ:

```
最新 dev-log: docs/dev-log/day-9-3.md (= 2026-05-07 由来)
今日: 2026-05-08

N をどうしますか?
- new: 新規 N (= day-10) で開始
- same: 同じ N (= day-9) で続行 → Step 3 で既存追記 / 新規分割を決定
- N=X: 明示で N を指定 (= 例: 「N=11」 で day-11 開始)
```

→ 局長応答で `target_N` 確定 → Step 3 へ。

> **分割運用について** (= day-9 で 3 分割の事例あり): 局長が休日など長時間作業時に「セッション分ける」 と都度宣言する運用。Skill は宣言を観測する側 (= `target_N` 同じで新規ファイル `day-N-X+1.md` を作成)。9 日間で 2 回観測 (= day-3, day-9) のため、自動キーワード判定は v0 で実装せず局長宣言を直接受ける。

### Step 3: 既存ファイル判定 + モード分岐

`target_N` 確定後、`ls docs/dev-log/day-${target_N}*.md` で全マッチ確認:

| 状態 | 動作 |
|---|---|
| ファイル無し | **新規モード** (= Step 4-A)、対象ファイル = `day-${target_N}.md` |
| `day-N.md` のみ存在 | **既存追記モード** (= Step 4-B)、対象 = `day-N.md` |
| `day-N-1.md` / `day-N-2.md` ... 存在 | **既存追記モード**、対象 = **最新の連番ファイル** (= 例: `day-N-3.md`) |
| 局長が「セッション分ける」 と明示 | **新規分割モード** (= 既存最新の番号 +1 で `day-N-X+1.md` 新規作成) |

### Step 4-A: 新規モード (= スケルトン生成 + 対話)

day-1/2 のフォーマット踏襲でスケルトンを提示し、空欄部分を **対話で材料引き出し → Claude が本文組み立て**。

#### 対話フロー

```
day-${target_N}.md を新規作成します。スケルトン作るので材料いくつか教えてください。

Q1. 今日のセッションを一言で表すと? (= ファイル名サブタイトルと H1 タイトルに入ります。例: "MVP 後 polish 初日")
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

→ Claude が本文組み立て → 局長レビュー → Step 5 へ。

### Step 4-B: 既存追記モード

#### 数字 3 箇所同期チェック (= memory feedback_dev_log_after_merge.md 核心ルール)

`grep -n` で現状値を抽出し、+1 した候補値を提示:

```
🔢 数字同期チェック (= 3 箇所同期、9 日間で同期漏れ実績ありの最重要箇所)

現状値の grep 結果 (= 3 箇所):
- ① リード文 (line ${X}): "1 PR マージ + 0 起票 + 1 close + 学び 35 確立"
- ② セクションヘッダ:
  - line ${X}: "### close した Issue (= 1 件)"
  - line ${X}: "### 起票した Issue (= 0 件)"  ← 該当時のみ (= 統計には常に出るがヘッダは 1 件以上の時のみ存在)
- ③ 統計 (line ${X}-${Y}):
  - マージした PR: 1 本
  - close した Issue: 1 件
  - 起票した Issue: 0 件
  - spec: 607 examples

候補値 (= +1 対象と不変の数字を分けて表示):
- ① リード文: "1 PR マージ + 0 起票 + 1 close + 学び 35 確立"
                  ↑ +1                ↑ +1 (= 今 PR が close したなら)
                  → "2 PR マージ + 0 起票 + 2 close + 学び 35 確立"
- ② セクションヘッダ: "### close した Issue (= 2 件)" (= +1)
- ③ 統計: マージした PR: 2 本 / close した Issue: 2 件 (= +1)

🟡 局長判断必要 (= PR 由来の数字、機械算出不可):
- spec examples 数 (= 今 PR で変化した?)
- rubocop offenses 数
- 学び番号 (= 今 PR で確立した?)
- 起票した Issue 数 (= 今 PR で起票した?)

→ 確認: 上記候補で edit してよいですか?
  Y: 全候補値で edit 実行
  edit:spec=612 edit:学び=36: 差分のみ修正 (= edit:KEY=VALUE 形式)
  N: 中止
```

#### 対話フロー (= 既存追記)

```
day-${target_N}-Y.md (= 既存) に PR #X 追記します。

Q1. PR の要点 (= 1 行内容、PR table 行に入れる)
Q2. close した Issue の概要 (= close Issue list 行に入れる)
Q3. 教訓・学び 追加? (= なければスキップ、あれば番号 + 一言)
Q4. 統計に追加すべき指標? (= spec 数変化 / rubocop 等、なければスキップ)
```

→ Claude が PR table 1 行 + close Issue list 1 行を整形 → Step 5 へ。

### Step 5: 本文組み立て + 局長レビュー

新規モード = スケルトン全文を提示、既存追記モード = 差分 (= 追加行 + 数字 edit) を提示。

```
本文プレビュー:
---
${生成された markdown}
---

→ この内容で edit 実行しますか?
  Y: edit 実行 → Step 6 へ
  edit:section=${セクション名}: ${特定セクション} を局長コメント反映して再生成 (= edit:KEY=VALUE 形式)
  N: 中止
```

### Step 6: ブランチ切り + commit + push + PR 作成

main 直コミット禁止 (= CLAUDE.md 絶対ルール)。以下を順次実行:

```bash
# 1. main から作業ブランチ切り
git checkout main
git pull origin main
git checkout -b docs/day-${target_N}-update-${PR番号}

# 2. ファイル編集 (= Edit / Write tool)

# 3. commit
git add docs/dev-log/day-${target_N}${サフィックス}.md
git commit -m "docs: day-${target_N} に PR #${PR番号} 反映"

# 4. push + PR 作成
# bash 固有のプロセス置換 (= sh 不可、heredoc + <(...) で本文を渡してシェル展開リスク回避)
git push -u origin docs/day-${target_N}-update-${PR番号}
gh pr create --base main \
  --title "docs: day-${target_N} 開発ログ追加/更新 (= PR #${PR番号} 反映)" \
  --body-file <(cat <<'EOF'
## Summary
- PR #${PR番号} (= ${PR title}) を day-${target_N}${サフィックス}.md に反映
- 数字 3 箇所同期更新 (= リード文 / セクションヘッダ / 統計)

## Test plan
- [ ] 数字 3 箇所が同期している (= grep 確認)
- [ ] 後輩が読んで価値ある内容になっている

🤖 Generated with [Claude Code](https://claude.com/claude-code)
EOF
)
```

PR URL を表示して終了。3 者並列レビューは局長判断で `/review-three` 起動 (= 第一群 #259 マージ後に Step 6 末尾で自動チェーン提案を追加予定)。

## ブランチ命名

`docs/day-${target_N}-update-${PR番号}` 形式 (= memory `feedback_dev_log_after_merge.md` の commit ルール踏襲、CLAUDE.md 種別 `docs/` 許可済)。

## アンチパターン

- **完全自動 edit (= D-1 級)**: 嘘ログ化、PR 由来数字 (spec / 学び番号) を Skill が勝手に推測してはいけない (= Day 9 で局長が D-2 確定、嘘ログ防止が weight_dialy 教材性の核心)
- **発火しなかったケースを放置**: 局長発言観測の漏れに気付いたら、その場で「dev-log 追記しますか?」 と提案する (= memory `feedback_dev_log_after_merge.md` の「マージ → dev-log → 次のタスク」 サイクル維持、Day 9 セッション 3 で確定)
- **dev-log 追記 PR を main 直コミット**: 絶対禁止、必ず作業ブランチで PR (= CLAUDE.md 絶対ルール、二段ガード = block-main-push.sh + .githooks/pre-push)
- **同一 PR の二重追記**: Step 1 起動時確認前に対象 dev-log ファイルを `grep "#${PR番号}"` で検索、既に追記済みの場合は表示して停止 (= 起動時確認スピンのコスト削減)

## 関連

- Issue #257 (= 本 Skill 新設の起源、Claude tooling 第一群 4 連発の 2 番目)
- memory `feedback_dev_log_after_merge.md` (= 機械化元の運用ルール、3 箇所同期核心ルール元)
- memory `project_claude_tooling_roadmap.md` (= 第一群 4 連発の位置付け、Skill 自動の使い分け軸)
- memory `project_plan_issue_skill_consideration.md` (= 「実演後判断」 ルール元、本 Skill v0 縮小の根拠)
- CLAUDE.md「📓 dev-log 運用フロー」 セクション (= 整合確認元)
- 過去 dev-log: `docs/dev-log/day-1.md` 〜 最新 (= テンプレ参照元、新規モードのフォーマット参考)
- Skill `propose-issue` (= 第一群 1 番目 PR #260 で整備、72 行 / 提案型 / 本 Skill = 自動発火型 の対比例)
- Command `/review-three` (= 第一群 3 番目 #259、マージ後に Step 6 末尾で起動チェーン提案を追加予定 = 第一群完走時のリファクタ伏線)

## v0 で削除した仕様 (= Day 10 以降の実演観察後に必要なら別 PR で追加)

memory `project_plan_issue_skill_consideration.md` の「実演後判断」 ルール適用で v0 縮小:

- **Step 3-1 分割切り出し判定 (= キーワード自動観測)**: 9 日間で 2 回観測 (= day-3, day-9) のため 3 回観測ルール未達。代わりに局長宣言を直接受ける形 (= Step 3 のテーブル末尾) で対応
- **数字派生同期チェック (= 学び番号 + 達成見出し)**: Issue #257 完了条件外、勝手拡張だった。3 者レビューで Day 10 以降の実運用で必要性が観測されたら別 PR で追加

→ 後輩教材として「**propose-issue 72 行 + dev-log-merge ${行数} 行 = 縮小思想で揃う**」 が第一群 4 連発の reference 価値。
