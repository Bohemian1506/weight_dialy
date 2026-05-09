---
description: セッション冒頭で 4 モード (= 学習 / 新規機能 / リファクタ / 調査・計画) のいずれかを宣言する。各モードの再開地点ソースを横断的に提示。
argument-hint: [モード名 (= 学習 / 新規機能 / リファクタ / 調査・計画、省略可)]
---

# /mode

**セッション冒頭でこのコマンドを 1 行打つだけで、今日の作業モードに応じた再開地点を即提示する**。

memory `feedback_session_mode_declaration.md` で確立した 4 モード運用 (= 学習 / 新規機能 / リファクタ / 調査・計画) を機械化するコマンド。セッション冒頭の手作業 (= 4 モードごとに散らばった再開地点ソースを横断検索して提示) を 1 コマンドで完結させる (= Issue #258、第一群 4 連発の 4 番目 = 最終)。

## 入力

モード: $ARGUMENTS

引数は **3 パターンのみ** (= YAGNI、観測ゼロのケースは載せない):

- **空**: 4 モード一覧 + 各再開地点サマリを全提示 (= モード未決の時の起動)
- **モード名のいずれか**: 該当モードのみ詳細提示
  - 日本語: `学習` / `新規機能` / `リファクタ` / `調査・計画`
  - エイリアス (= キーボード打ちやすさ): `study` / `feature` / `refactor` / `investigate`
- **その他文字列**: 4 モード名のいずれかに振り分けるか確認 (= 先回りで決めない、`feedback_session_mode_declaration.md` の「該当トラックなし」 対応踏襲)

## 4 モード × 再開地点ソース対応表

| モード | 再開地点ソース | 提示内容 |
|---|---|---|
| 🎓 学習 | memory `project_ruby_basics_learning_track.md` | 完了済み Lesson 一覧 + 次 Lesson 候補 (= 1-3 個推奨) |
| 🚀 新規機能 | GitHub Projects v2 #9 「weight_dialy roadmap」 + `gh issue list` | Tier 0/1/2 残件 + 推奨着手順 |
| 🔧 リファクタ | `docs/refactor-candidates.md` | Tier 1/2/3 残件 + 着手前テスト確認の指針 |
| 🔍 調査・計画 | 専用ソースなし (= タスクごと) | `/plan-issue` Command 起動を提案 + 必要なら api-researcher / Explore を先に走らせる案内 |

**SSOT (= Single Source of Truth)**: 上記対応表と memory `feedback_session_mode_declaration.md` がズレた場合は **memory が正** (= Command 本文は実行時に古くなりうるが memory は毎セッション自動読み込みされるため、Day 11 strategic 論点 2 で確立した運用原則、第一群全 Command/Skill 共通)。

## フロー

### Step 1: 引数解釈

引数を 3 パターンに振り分ける:
- 空 → Step 2 (= 全モード提示モード)
- 4 モード名 (or エイリアス) → Step 3 (= 単一モード提示モード)
- 不明な引数 → 「学習 / 新規機能 / リファクタ / 調査・計画 のどれですか?」 と確認、振り分け後に Step 3

#### 引数別の挙動例

```
/mode           → Step 2 (= 全モード提示)
/mode 学習      → Step 3-A
/mode feature   → Step 3-B (= エイリアス)
/mode リファクタ → Step 3-C
/mode foo       → 「学習 / 新規機能 / リファクタ / 調査・計画 のどれですか?」 と確認
```

### Step 2: 全モード提示モード (= 引数なし)

各モードを 2-3 行のサマリで提示、ユーザーがどのモードに入るか選びやすくする。各サマリは Step 3 のソース読み出しを **軽量実行** で済ませる (= memory header 抽出 / `gh issue list` 件数のみ / `docs/refactor-candidates.md` Tier 件数カウント)。

出力例 (= プレースホルダーは `<N>` 表記、実値は memory / Issue 一覧 / `docs/refactor-candidates.md` から取得):

```
セッション再開地点 (= 4 モード横断)

🎓 学習 (= memory `project_ruby_basics_learning_track.md`)
  Lesson 1-<N> 完了 / 次 Lesson 候補 <X> 個

🚀 新規機能 (= GitHub Projects v2 #9 + Issue 一覧)
  Tier 0 緊急: <N> 件 / Tier 1 v1.0: <M> 件 / Tier 2+ v1.1+: <K> 件

🔧 リファクタ (= docs/refactor-candidates.md)
  Tier 1 大物: <N> 件 / Tier 2 中物: <M> 件 / Tier 3 小物: <K> 件

🔍 調査・計画 (= 専用ソースなし、タスクごと)
  `/plan-issue` で対話開始 / api-researcher / Explore チェーン

→ どのモードで進めますか?
```

ユーザー選択 → Step 3 の該当サブステップへ。

### Step 3: 単一モード提示モード

#### 3-A. 🎓 学習モード

```bash
# memory 読み出し (= ホーム側、ファイル直 Read)
# 完了済み Lesson + 次回候補を抽出
```

提示内容:
- 完了済み Lesson 1-N を 1 行ずつ復習 (= 番号 + タイトル + 1 行要約)
- 次 Lesson 候補から **1-3 個推奨** (= 副局長判断、各候補の意義 + weight_dialy コードへの繋がりを 1 行ずつ)
- ユーザー選択 → Lesson 開始 (= memory `feedback_codebase_walkthrough_cadence.md` 1 概念 1 応答ルール厳守)

#### 3-B. 🚀 新規機能モード

```bash
# Projects board の状況確認 (= weight_dialy roadmap)
gh project item-list 9 --owner Bohemian1506 --format json --limit 50

# 直近の Open Issue 一覧
gh issue list --state open --limit 20

# 第一群 4 連発の残件確認 (= memory `project_claude_tooling_roadmap.md`)
```

Tier ごとに残件を整理して提示:
- **Tier 0 (= 緊急)**: あれば即着手
- **Tier 1 (= v1.0)**: 第一群 4 連発の残 / Tier 1 大物 3 件 (= Phase 3 三重防衛 / Capacitor OAuth / daisyUI 全置換)
- **Tier 2+ (= v1.1+)**: 中期送り

推奨着手順 (= 副局長判断) を 1-3 個提示、各候補の判断軸 (= 締切 / ROI / 教材性) を 1 行ずつ。

ユーザー選択 → 該当 Issue 着手 / 別 Issue ならその番号で起票 (= `/plan-issue` Command チェーン)。

#### 3-C. 🔧 リファクタモード

```bash
# docs/refactor-candidates.md の読み出し (= ファイル直 Read、CLAUDE.md「cat 避ける」 ルール厳守)
```

提示内容:
- Tier 1 / 2 / 3 ごとに残件を整理
- **着手前テスト確認の指針** (= `docs/refactor-candidates.md` 冒頭「着手前にテスト確認」 を引用): その候補に対応する RSpec / system spec があるか、なければテスト追加 PR を先に切る
- 推奨着手 1-3 個 (= 副局長判断)

ユーザー選択 → ブランチ切る前に **テスト存在確認** → 着手。

#### 3-D. 🔍 調査・計画モード

専用ソースなし (= memory `feedback_session_mode_declaration.md` の方針通り、Issue #258 起票時の `investigation` ラベル想定は **PR 実装時に格下げ** = memory `feedback_self_proposal_relativization.md` 自己完結型 6 例目)。

提示内容:

```
🔍 調査・計画モード

専用ソースなし、タスクごとに対話開始が筋。何を調査・計画しますか?

- 外部仕様 (= API / 公式ドキュメント / 公式仕様調査) → `api-researcher` Agent を先に走らせる
- 内部探索 (= 既存コードの所在 / 命名 / 関係性) → `Explore` Agent を先に走らせる (= 注意: コードレビュー / 横断分析には `general-purpose` Agent)
- 設計判断 / Issue 化 → `/plan-issue` Command で対話開始 (= 1 Issue / 1 機能 / 1 PR ルール)
```

ユーザー応答 → 該当 Skill / Agent / Command 起動。

## この Command を Skill にしなかった理由

memory `project_plan_issue_skill_consideration.md` の判断軸 + 第一群 3 番目 `/review-three` で確立した使い分け軸を踏襲:

1. **意図的なモード宣言が筋**: ユーザー側の頭の整理込みで、宣言行為自体に教材性
2. **Skill 自動発火だと邪魔**: 「いやモード切替じゃなくて雑談したい」 場面で止めにくい
3. **明示打ちで意図的切替を強制**: `/mode リファクタ` 1 行で完結 (= UX 良)
4. **「今は要らない」 場面で止めたい** = Command 明示形式の代表例 (= `/review-three` と同じ判断軸)

第一群 4 連発で確立した使い分け軸:
- **Skill 自動** (= `/dev-log-merge`): 漏らしたら困る + 発火条件明確 + 止めたい場面少
- **Skill 提案型** (= `propose-issue`): 発火シーン分かりにくい + 二段構えで起動
- **Command 明示** (= `/review-three` / `/mode`): 「今は要らない」 場面で止めたい / 教材性として意図的起動が筋

`/review-three` との細部差異: `/review-three` は **Agent 起動コスト高** (= 3 Agent 並列で大量 token) も Skill 非採用理由の 1 つだが、本 Command は **Agent 起動なし** (= memory / ファイル / Issue 一覧読み出しのみで完結 = コスト低) のためこの理由は該当しない。第一群最終ピースとして「コスト軸でも 2 種類」 の使い分け実例 = `.claude/README.md` 体系整備時の教材になる。

## 注意事項

- 4 モードの再開地点は時間と共に陳腐化するので、**各セッション終了時に該当ソースを更新する習慣を維持** (= memory `feedback_session_mode_declaration.md` の核心、本 Command 起動時に「最終更新日」 が古ければ警告)
- Command 本文の対応表と memory `feedback_session_mode_declaration.md` がズレた場合は **memory が正** (= 第一群全体の SSOT 原則)
- 引数で不明なモード名を渡された場合、4 モード名のいずれかに振り分けるか確認 (= 先回りで決めない、memory の「該当トラックなしの対応」 踏襲)
- **`/mode` を「セッション冒頭」 以外で打つことも可** (= 途中でモード切替したい時にも使える、Command 明示形式の利点)
- 起動コストは Step 2 (= 全モード提示) でやや高い (= 4 ソース全読み出し)、Step 3 (= 単一モード) は軽量。日常的には Step 3 直行が筋

## 関連

- memory `feedback_session_mode_declaration.md` (= 機械化元 / SSOT、4 モードの設計と運用ルール)
- memory `project_ruby_basics_learning_track.md` (= 学習モードのソース)
- `docs/refactor-candidates.md` (= リファクタモードのソース)
- GitHub Projects v2 #9 「weight_dialy roadmap」 (= 新規機能モードのソース、ID `PVT_kwHOCoLlo84BWYSm`)
- `.claude/commands/plan-issue.md` (= 調査・計画モードからチェーンする Command)
- `.claude/commands/review-three.md` (= 第一群 3 番目、Command 明示形式の先行例)
- Skill `propose-issue` (= 第一群 1 番目、提案型 Skill の先行例)
- Skill `dev-log-merge` (= 第一群 2 番目、自動発火 Skill の先行例)
- Issue #258 (= 本 Command 起源、第一群 4 連発の 4 番目 = 最終)
- memory `feedback_self_proposal_relativization.md` (= `investigation` ラベル想定を格下げした実例 = 自己完結型 6 例目候補)
- **後続予定**: 本 PR マージで第一群 4/4 完走、続けて **`.claude/README.md` Skill / Command 体系整備 Issue 起票** (= 4 件の使い分け軸を 1 ファイルに集約、本 Command の使い分け表 + `/review-three` との差異記述が下書き元として機能する、strategic-reviewer 推奨 A by Day 9-2)
