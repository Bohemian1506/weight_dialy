# Day 15 開発ログ (2026-05-14、/insights レポート起点 + canon-check 仕組み化 案 A 完走 (= Issue #331 + PR #332))

> **⚠️ 連番補足**: 本来 day-15 = 2026-05-13 (= 連番計算上の対応日) だが、2026-05-13 は作業なしのため day-15 を **2026-05-14 分に充当**する (= 連番優先 / 日付 1 日ズレ)。以降 day-N+1 = N 日後ではなく「作業 N 回目」 とする運用に変わる可能性あり (= 要観測)。

day-14-2 (= v1.0 Android 配布完走 + #314 + #317 + #320 session 永続化 + #325 i18n legal パイロット) からバトンタッチ。本セッションは局長操作の `/insights` レポートを起点に Claude tooling 第二群の着手判断 → **canon-check 仕組み化 案 A** (= CLAUDE.md 規範化) を完走。

**Day 15 達成サマリ**: 1 PR (#332) マージ + 1 Issue (#331) close + 1 Issue (#331) 起票 (= 同セッション完走型 4 例目候補) + 3 者並列レビュー 🟡 4 件 + 🟢 3 件吸収 + 試運用判断基準 3 軸 (= 自発発火率 / 矛盾発見回数 / 抜け漏れ) 定量化 + CLAUDE.md 規範化と memory 化の **撤回コスト軸分離** ルール確立 (= 教訓 1)。案 B (= `/canon-check` Skill) は試運用 2-3 セッション後判断。

---

## 🎯 セッション目標

- [x] `/insights` レポートの起点活用 (= Claude tooling 第二群着手判断)
- [x] canon-check 仕組み化の A → B → C 段階導入路線確立
- [x] 案 A (= CLAUDE.md 規範化) 完走
- [ ] 案 B (= `/canon-check` Skill) は試運用 2-3 セッション後の別 Issue で起票 (= 持ち越し)

---

## ✅ 達成事項

### PR テーブル

| PR | タイトル | Issue | 種別 |
|---|---|---|---|
| #332 | docs: canon-check 標準手順を CLAUDE.md に追記 (= /insights 案 A、#331) | #331 | docs |

### 起票/close Issue

| Issue | タイトル | 状態 |
|---|---|---|
| #331 | docs: canon-check 標準手順を CLAUDE.md に追記 (= /insights 摩擦解消 案 A) | 起票 + 同 PR で close |

### CLAUDE.md 追記内容 (= 32 行)

- 「🔍 canon-check 標準手順 (= 設計判断前の自発検証)」 セクション新設
- 配置: 「📓 dev-log 運用フロー」 と 「⚠️ やってはいけないこと」 の間
- 4 ステップ (= 列挙 / 引用 / 矛盾チェック / ドラフト or 相談) + 適用範囲 4 種類 ✅ + 除外 3 種類 ❌ + 出力フォーマット例 (= 衝突なし 3 行 + 衝突あり 1 行)

---

## 🔥 トラブル

特になし (= 3 者並列レビュー 🟡 4 件 + 🟢 5 件は通常のフィードバック吸収範囲内、PR 中の追加コミット 1 回で吸収完了)。

---

## 🧠 教訓

### 教訓 1: CLAUDE.md 規範化と memory 化は **撤回コスト** で軸を分ける

3 者レビュー (= strategic) で発見:

- 案 A (= CLAUDE.md 規範化) は `/insights` 1 例で実施したが、これは memory `feedback_self_proposal_relativization.md` の 3 回観測ルール (= memory 化判断) とは別軸。
- 理由: **撤回コストの非対称性**:
  - **memory 化** = MEMORY.md 更新 + 関連 PR 連鎖 → 撤回コスト高 → 3 回観測ルール厳格適用
  - **CLAUDE.md 規範化** = revert PR 1 本 → 撤回コスト低 → 摩擦の早期解消優先
- main 直 push 禁止ガードも 1 件の事故で即機械化された前例あり (= 同様の判断軸)。

**How to apply**: 「3 回観測ルール」 は撤回コスト高の判断 (= memory 化) のみに厳格適用。撤回コスト低の判断 (= CLAUDE.md 規範化、コード変更) は 1 例でも入れて事後 revert で対応する。観測 2 例目以降で memory 化検討。

### 教訓 2: `/insights` レポートは Claude tooling 拡張ロードマップの再相対化触媒として機能した

- 学び 36 (= 外部触媒型) のさらなる事例。
- Anthropic の 184 セッション統計が「Claude が canon を確認せず仮定で進む」 を筆頭摩擦と提示 → weight_dialy の現有 memory 体系 (= 3 ステップ思想 / sketch-* / 3 回観測ルール) を再確認して仕組み化に進めた。
- 単独で気付くのは難しい摩擦が「外部統計の上位指摘」 で言語化された。

**How to apply**: `/insights` は定期実行候補 (= 月 1 回など)。記録的セッションだけでなく仕組み化セッションでも見直す。

### 教訓 3: 段階導入 (A → B → C) の判断基準を事前定量化することで「やめどき」 を明文化

- 案 A 採用時に、案 B 起動条件を 3 軸 (= 自発発火率 N/M / 矛盾発見回数 / 抜け漏れ) で事前定量化。
- 7-12 で Day 14-2 教訓 4 「Kotlin 越境 vs JS 完結の境界線越え禁止」 + Day 13 PR #294 「不発閾値 3/5 例事前確定」 と同系統 = **撤退・進行判断の事前数値化**。
- 試運用後の判断者 (= 局長) の主観を減らし、後輩追跡可能にする。

**How to apply**: 段階導入を採用する PR では、次段階の起動条件を 3 軸以上で事前定量化して PR description / Issue 本文に記載する。

---

## 📊 統計

- **PR マージ**: 1 (= #332)
- **Issue close**: 1 (= #331)
- **Issue 起票**: 1 (= #331、同 PR で close)
- **3 者並列レビュー**: 3 名 (= code + strategic + design)
- **🟡 推奨指摘吸収**: 4 件 (= 見出し重複 + 用語説明 + 試運用基準 3 軸 + 規範化判断)
- **🟢 提案採用**: 3 件 (= 表注釈・サンプル / Issue リンク / 末尾参照集約)
- **CLAUDE.md 追加分量**: 32 行 (= 新セクション)

---

## How to apply (= 次セッション以降に持ち越す観点)

1. **canon-check 自発検証の実運用ログ**: 4 種類分岐点 (= 新機能 / UI / memory 化 / リファクタ) ごとに発火率 N/M を観測。次 2-3 セッションで 70% 未満なら案 B (= Skill) 起動判断。
2. **案 B 起票判断材料の集約先**: (a) 自発発火率 (b) ユーザー矛盾発見回数 (c) 案 A で吸収できなかった抜け漏れ — の 3 軸を Issue #331 にコメント追記の形で集約。
3. **CLAUDE.md 規範化と memory 化の軸分離ルール** (= 教訓 1) を `feedback_self_proposal_relativization.md` の補強として記載検討 (= 但し 3 回観測ルール準拠で別事例 2 件観測待ち)。
4. **dev-log 連番ルール明文化**: 本回の day-15 が「作業 N 回目」 形式に変質する分岐点 (= 5/13 作業なしで 1 日ズレ)。CLAUDE.md の「N の判定: 開始日からの連番」 と実運用にズレが出る可能性。次回 day-N 命名時に CLAUDE.md 記述を再検討。

---

## 関連リソース

- `/insights` レポート (= 2026-05-14、`file:///home/bohemian1506/.claude/usage-data/report.html`)
- PR #332 (= 本セッションの主成果)
- Issue #331 (= 判断ログ + レビュー反映補強コメント)
- memory `feedback_self_proposal_relativization.md` (= 3 回観測ルール、本 PR で別軸適用)
- memory `feedback_light_issue_one_pr_completion.md` (= 軽量 Issue 1 PR ルール、本 PR で適用)
- memory `feedback_always_three_reviewers.md` (= 3 者並列レビュー必須)
- memory `project_claude_tooling_roadmap.md` (= 本 PR で第二群に着手)
