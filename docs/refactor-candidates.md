# 📋 リファクタ候補ダッシュボード

> **目的**: 「今日はリファクタモード」と宣言した時に、ここから 1 つ選んで着手するための候補一覧。
> **更新方針**: 候補が増えた時に追記。完了したら取り消し線 + 注記 (= 完了内容 / 発見 / 見送り判断) で記録、該当日の `docs/dev-log/day-N.md` にサマリ記載。後輩がダッシュボードから時系列を追えるよう履歴を残す (= 定期的に archive 候補)。

## 🎯 選び方の指針

- **着手前にテスト確認**: その候補に対応する RSpec/system spec があるか。**なければテスト追加 PR を先に切る**。
- **規模感の目安**: 1 PR で完結する粒度。大きい候補は子 Issue に分割。
- **教材性を意識**: weight_dialy は学習教材も兼ねるため、リファクタ過程自体が後輩への教材になる切り口を優先。

---

## 🥇 Tier 1: 大物 (= 着手前に Issue 起票推奨)

### 1. Phase 3 三重防衛 (`allow_browser`) の解消
- **場所**: `app/controllers/application_controller.rb:14-23`
- **現状**: Capacitor / Android WebView / Mobile Chrome の 3 種を bypass する応急対応 (PR #140 → #142 → #146 → 子 6 で段階拡張)
- **ゴール**: Capacitor の deep link / app links で OAuth 後にアプリへ戻る経路を確立 → bypass 不要に
- **副作用懸念**: Web 版モバイル Chrome ユーザー向け allow_browser が現状緩んでいる (= セキュリティ実害なしだが UX 防御が弱まっている)
- **関連**: コメントで明示「v1.1 で対応予定」
- **見積**: 中 (= Capacitor 周りの再現環境とハイブリッド OAuth 知識必須)
- **前提テスト**: OAuth 流入経路の system spec が必要

### 2. ~~Capacitor OAuth ブリッジ整理 (`sessions_controller.rb`)~~ ✅ Day 13-4 縮小完了
- **場所**: `app/controllers/sessions_controller.rb`
- **完了内容**: Day 13-4 で `bridge_to_capacitor(user)` private 抽出により `create` メソッド 30 行 → 19 行に縮小
- **発見 (= 規模感陳腐化)**: 起票時 (= Day 7-8) の「ゴール」 (= `sessions#create` 入口 1 本化 / session 確立共通化 / Concern 化検討 / spec) は **Issue #228 等で 95% 達成済**、本 PR は残滓 (= `create` 内 Capacitor 分岐 30 行) の private 抽出のみ。起票時「大物」 判定は時系列で「中物以下」 に陳腐化していた
- **見送り判断**: logger メッセージ統一は既存コメント「経路差を明示するため共通化しない」 と矛盾 → 同セッション内自己発火で格下げ
- **教材ポイント (= 後輩向け)**: 「大物」 ラベルは起票時判断、5 日越しで再評価が筋。実態調査 1 ステップを着手前に挟む運用 = `docs/refactor-candidates.md` 全 Tier に共通の運用候補

### 3. daisyUI → sketch-* 全置換
- **場所**: `app/views/**/*.html.erb` 全般 (+ partials)
- **現状**: 新規利用は既に禁止、既存は触ったタイミングで置換中
- **ゴール**: `btn` / `card` / `navbar` / `alert` 等を sketch-* に統一
- **見積**: 大 (= 1 PR 1 partial の小分けが筋)
- **前提テスト**: なし (= system spec が薄いため、1 partial ずつスクショ目視 + 触ったタイミング置換が現実解)
- **関連**: CLAUDE.md「🎨 スタイル使い分けルール」

---

## 🥈 Tier 2: 中物 (= 単発 PR で済む粒度)

(現状なし。Day 9 で全 3 件完走 = #4 webhooks_controller 切り出し / #5 旧 BuildHomeDashboardService state 命名 = Issue #161 / #6 → #5 繰上げ後 CalorieAdvice body 分離)

---

## 🥉 Tier 3: 小物 (= 暇なときに)

(現状なし。発見次第追記)

---

## 📚 参考

- 過去のリファクタ実績は `docs/dev-log/day-N.md` の各日サマリに散在
- 業界標準アーキテクチャ教材化は **Issue #219** で別建てされている (= リファクタとは独立トラック)
- 関連メモリ:
  - `feedback_codebase_walkthrough_cadence.md` (= コード解説/学習ペース)
  - `project_ruby_basics_learning_track.md` (= 学習進捗)
  - `feedback_session_mode_declaration.md` (= 4 モード運用)
