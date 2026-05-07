---
name: propose-issue
description: ユーザーが未着手タスクへ言及した時に /plan-issue での Issue 化を提案する。即起動はしない、ユーザー Yes で Command 起動の二段構え。
---

# Skill: propose-issue

`/plan-issue` Slash Command (= 軽量対話で Issue 化) の **入口提案役**。Claude が会話の流れを観測し、未着手タスクへの言及を拾った時に「`/plan-issue` で詰めますか?」 と一言提案する。

## 設計思想

- **即起動禁止**: ユーザーがこの Skill 名を明示で打った場合を除き、Skill 自体が `gh issue create` を行うことはない
- **二段構え**: Skill = 提案 → ユーザー Yes → `/plan-issue` Command 起動 (= コントロール感をユーザー側に渡す)
- **誤発火を抑える方が漏れより重要**: description マッチで毎度発火すると鬱陶しい。「未着手タスクの言及」 という狭い範囲で絞る

## 発火シーン (= 4 つ)

以下のいずれかをユーザー発言から観測したら 1 行で提案する。

### 1. 次タスク言及

ユーザーが「次は X やりたい」「Y もしないと」「これから Z」 等、未着手の作業を口にした時。

**提案文例**:
> 「`/plan-issue X` で詰めますか? (= 軽量対話で Issue 化)」

### 2. 派生 Issue 候補

3 者並列レビュー / 実装中に「これは別 Issue で対応」「派生で起票」 等、現タスクから切り離す判断が出た時。

**提案文例**:
> 「派生 Issue として `/plan-issue` で起票しますか?」

### 3. polish ネタ観察

UI 微調整 / コピー再考 / 細部の違和感に言及した時 (= memory `feedback_ui_polish_at_end.md` の「機能完成後にまとめる」 タイミングを思い出させる)。

**提案文例**:
> 「polish ネタとして `/plan-issue` で Issue 化しておきますか?」

### 4. dev-log 未着手項目化

dev-log 振り返りで「これは Day N 以降」「次セッションで」 等、未来日にずらす言及が出た時。

**提案文例**:
> 「Day N 以降の Issue として `/plan-issue` で詰めますか?」

## 発火させない場面 (= 明示)

以下では **絶対に提案を出さない**。誤発火は鬱陶しさで Skill 全体の信頼を毀損する。

- **軽微 PR の対話中** (= Dependabot / typo 修正 / spec 数値更新のみ) — そもそも Issue 化する話題でない
- **質問雑談** (= 「これは何?」「なんで X してるの?」 系の理解確認) — タスク提案ではない
- **既着手タスクの内部対話** (= 今やっている実装の細部を相談中) — 現タスクに集中させる
- **memory 化検討時** (= 「3 例目達成」「知見を残したい」 系) — Issue 化と判断軸が違うため `feedback_*.md` 新規作成が筋。Skill `propose-issue` の範囲外
- **ユーザーが「これは Issue にしない」 と明示した直後** — 一度断られたものを再提案しない

## 提案後のフロー

ユーザー応答パターン:

- **Yes / 「お願い」 / 「詰めて」** → `/plan-issue <topic>` を起動 (= Slash Command の Step 1 へ)
- **No / 「あとで」 / 「いい」** → 「OK、続けます」 で会話に戻る、再提案しない
- **保留 / 「考える」** → 「気が変わったら呼んでください」 で会話に戻る

## 関連

- Slash Command `.claude/commands/plan-issue.md` (= 提案後の本起動先、軽量化済)
- memory `project_plan_issue_skill_consideration.md` (= ハイブリッド構成の予言、Day 2 起源)
- memory `feedback_self_proposal_relativization.md` (= Skill 名を `plan-issue` から `propose-issue` に格下げした判断ログ)
- memory `feedback_ui_polish_at_end.md` (= 発火シーン 3 の根拠)
- Issue #256 (= 本 Skill 新設の起源、ハイブリッド構成 4 連発の 1 番目)
