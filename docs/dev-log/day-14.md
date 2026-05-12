# Day 14 開発ログ (2026-05-12、v1.1 タグ Issue 着手シリーズ 軽量 3 連 完了 (= #176 + #175 + #190))

day-13-4 (= リファクタ Tier 1 大物 #2 縮小完了) からバトンタッチ。局長指示「ISSUE を減らしたい」 = open Issue 20 件を v1.1 タグ 7 件着手から減らす方針確定 → 軽量 3 連 (#176 → #175 → #190) 順に実行 → **本セッションで 3/3 完走**。Phase 3 OAuth ブリッジ工事痕 (= #176 + #175) + viewport-fit=cover 補正 (= #190) で v1.1 タグ着手 sprint 立ち上げ。

**Day 14 達成サマリ**: 3 PR (= #299 + #301 + #302) マージ + 3 Issue (= #176 + #175 + #190) close + 1 Issue (= #303) 起票 + 3 者並列レビュー指摘 計 13 件全件吸収または別 Issue 切り出し (= 軽量 Issue 1 PR ルール 20 → 21 → 22 例目連続達成) + 学び 36 サブカテゴリ「コード内物理保存型」 観測 2 件 (= 墓標型 PR #301 + 数式 WHY 型 PR #302) + サブカテゴリ定義明文化が先という方向修正 + メタ教訓「meta タグ宣言 + CSS env() 補正は 2 PR で 1 機能完成」 確立 (= 1 例目観測、Issue #303 が 2 例目候補)。

---

## 🎯 Day 14 の目標

1. open Issue 20 件 → 着実に減らす (= v1.1 タグ 7 件着手から)
2. 軽量 3 連 (#176 → #175 → #190) を順に close
3. 大規模 / 中規模 v1.1 Issue (= #174 / #177 / #178 / #291) は別セッションで判断

→ 1, 2 完走、3 は別セッション送り。純減 = 20 → 18 件 (= 3 close - 1 新規起票 #303)。

---

## 🏆 達成したこと

### マージ済み PR (= 3 本)

| PR | Issue | 内容 |
|---|---|---|
| #299 | #176 | feat(ops): OneTimeLoginToken GC ジョブ + auto_login Cache-Control 整備。**+106/-1 行 / 7 ファイル**。Phase 3 OAuth ブリッジ用 `OneTimeLoginToken` (= TTL 30s、`/auto_login` で 1 回消費) の運用整備。(A) `CleanupOneTimeLoginTokensJob` 新設 (`expires_at < 1.day.ago` の `delete_all` を Solid Queue recurring `at 4am every day` で日次実行) + (B) `SessionsController#auto_login` に `Cache-Control: no-store` (= Turbo Drive prefetch 予防) 1 行追加。3 者並列レビュー指摘 7 件 (= **🟡 軽微 3 件 (= `expires_at` インデックス追加 + Cache-Control 慣用形 + spec `freeze_time`) + 🟢 提案 4 件 (= recurring.yml 語順 + subject→let + Cache-Control spec 補足 + 単純化判断コメント)**) を **全件本 PR 吸収** = **軽量 Issue 1 PR ルール 20 例目連続達成** (= Day 13-4 19 例目候補確定 + 本 PR 続伸)。`Closes` 自動 close は PR body 書き忘れ → 手動 `gh issue close 176` で対応 (= 副次知見)。33 spec examples / 0 failures / 85 files rubocop / 0 offenses。新規 migration 1 件 |
| #301 | #175 | refactor(cleanup): Phase 3 完成後の工事痕 2 件を除去。**+8/-23 行 / 3 ファイル**。Phase 3 完成 (= PR #149-#154) 後の工事痕集約除去。(A) `public/.well-known/assetlinks.json` 物理削除 (= Day 7 Phase 2b 残骸、PR #154 で AssetLinks intent-filter 削除後の死にファイル) + (B) `ApplicationController#allow_browser` の「保険 2: Mobile Chrome bypass」 1 行削除 + コメント整理 (= 三重防衛 → 二重防衛、副作用段落削除、Phase 3 完成更新)。3 者並列レビュー指摘 3 件 (= **🟢 Nit 2 件 (= PR 番号補強 + spec コメント冗長化解消) + 🟢 strategic 提案 1 件 (= dev-log/memory 追記、別作業送り)**) を **Nit 2 件本 PR 吸収** + strategic 提案は本 dev-log で対応 = **軽量 Issue 1 PR ルール 21 例目連続達成**。`Closes #175` 自動 close 成功。120 spec examples / 0 failures / 85 files rubocop / 0 offenses。memory `feedback_grep_zero_after_fix.md` 適用 (= `Mobile Chrome` / `保険 2` / `assetlinks` grep ゼロ確認、コメント残置のみ意図的) |
| #302 | #190 | feat(ui): navbar に safe-area-inset 補正を追加。**+12/-4 行 / 2 ファイル**。iPhone PWA / Dynamic Island 端末でノッチ侵入による navbar 上辺欠けを回避。`.sketch-navbar` の `padding-top` を `max(8px, env(safe-area-inset-top, 0px))` に拡大 + `:root --navbar-height` を `calc(64px + max(0px, env(safe-area-inset-top, 0px) - 8px))` に変更 (= flash toast の top-offset が連動して下に追従)。3 者並列レビュー指摘 6 件 (= **🟡 軽微 1 件 (= `application.html.erb:85` コメントドリフト、code/design 同根) + 🟢 提案 5 件 (= env fallback 明示 + padding-bottom WHY + PR description メタ教訓追記 + Issue コメント判断ログ + 別 Issue 起票)**) を **本 PR 4 件吸収 + マージ後作業 2 件 (= Issue #190 判断ログコメント + Issue #303 起票)** = **軽量 Issue 1 PR ルール 22 例目連続達成**。`Closes #190` 自動 close 成功。615 spec examples / 0 failures / 85 files rubocop / 0 offenses |

### close した Issue (= 3 件)

- **#176** (= v1.1: OneTimeLoginToken 運用整備) — PR #299 で close (= 手動 close、PR body Closes 書き忘れ)
- **#175** (= v1.1: Phase 3 cleanup set) — PR #301 で close (= `Closes #175` 自動)
- **#190** (= v1.1: safe-area-inset 補正) — PR #302 で close (= `Closes #190` 自動)

### 起票した Issue (= 1 件)

- **#303** (= v1.2: modal 系 safe-area-inset 補正) — PR #302 design-reviewer 提案 1 由来、settings 退会モーダル + welcome モーダルの follow-up

---

## 🧠 教訓ハイライト (= 2 件、観測 + 確立)

### 学び 36 サブカテゴリ「コード内物理保存型」 観測 2 件 + 認定保留 (= 定義明文化先行へ方向修正)

**前提**: memory `feedback_self_proposal_relativization.md` の 3 サブカテゴリ (= 自己完結型 + 学び 36 外部触媒型 + memory 整理 PR 単独) は Day 12-2 で確定済。

**本日観測 2 件**:

| PR | コメント性質 | 例示 |
|---|---|---|
| PR #299 | 「Issue 仮説 → PR 確定の単純化理由」 (= 数式 WHY 型) | `# (Issue #176 では expired_or_used scope 案だったが、TTL 30s なら expires_at 一本で網羅できるため単純化)` |
| PR #301 | 「削除された防衛コードの履歴痕跡」 (= 工事痕墓標型) | `# 旧「保険 2: Mobile Chrome bypass」は PR #175 で削除` |
| PR #302 | 「現在動作中の数式の WHY」 (= 数式 WHY 型、PR #299 と同型) | `# iPhone PWA / Dynamic Island 端末で padding-top を env(safe-area-inset-top) に拡大、ノッチ侵入回避 (= Issue #190)` |

**方向修正 (= strategic-reviewer PR #302 論点 2 由来)**: 3 例目認定の前に **サブカテゴリ定義の明文化** が先。3 件の観測内容は 2 種類混在 (= 墓標型 1 + 数式 WHY 型 2) のため、定義が緩いと「実は別物 2 種類が混ざってた」 と後で分解が必要になる。memory `feedback_self_proposal_relativization.md` の不発閾値 3/5 例事前確定ルール (= Day 13 #294) を守るため、定義固定 → 過去 PR を逆引き分類の順で進める。

**How to apply**: memory 整理 PR (= 別 Issue 起票候補) で「コード内物理保存型」 サブカテゴリの定義を 2 種類 (= 墓標型 + 数式 WHY 型) で先行確定、その後 3 例目以降の累積を待つ。

### メタ教訓「meta タグ宣言 + CSS env() 補正は 2 PR で 1 機能完成」 確立 (= 1 例目観測)

**前提**: PR #189 (= `<meta name="viewport" content="...,viewport-fit=cover">` 宣言) を発表会直前に追加した時、code-reviewer の指摘で「CSS 側で `env(safe-area-inset-*)` を使った補正がないと宣言が活用されない」 と判明 → Issue #190 起票 → PR #302 で補正完成。

**確立**: meta タグ宣言は CSS env() 補正と **対で初めて効く**。片方だけ書くと「動いた気がするが効いてない」 状態。同パターンは将来も発生 (例: `theme-color` + dark mode CSS / `apple-mobile-web-app-capable` + status bar CSS)。

**How to apply**: meta タグを追加する PR では **CSS 側のペアリング** を同一 PR で出すと、code-reviewer 指摘 → Issue 起票 → 別 PR で補正、という 3 段往復が 1 PR に短縮できる。

**1 例目観測**: 次の観測 = Issue #303 (= modal 系 safe-area-inset 補正、同パターン 2 例目候補)。3 例目以降で memory `feedback_meta_declaration_needs_css_pairing.md` 等の正式 memory 化検討。

---

## 📊 統計

- マージした PR: 3 本 (= #299 + #301 + #302)
- close した Issue: 3 件 (= #176 + #175 + #190)
- 起票した Issue: 1 件 (= #303)
- spec: 615 examples / 0 failures
- rubocop: 85 files / 0 offenses
- 教訓: 2 件 (= 学び 36 サブカテゴリ観測 2 件 + 定義明文化方向修正 + メタ教訓 1 例目)
- open Issue 純減: 20 → 18 件 (= 3 close - 1 起票)

---

## 🎯 残タスク

- [ ] **#303** v1.2: modal 系 safe-area-inset 補正 (= settings 退会モーダル + welcome モーダル、PR #302 follow-up)
- [ ] **TZ 検証** マージ後 24h 以内に Solid Queue ログで `cleanup_one_time_login_tokens` 実発火時刻確認 (= PR #299 strategic 論点 1 由来)
- [ ] **学び 36 サブカテゴリ定義明文化** memory `feedback_self_proposal_relativization.md` 整理 PR (= 「コード内物理保存型」 を 2 種類 = 墓標型 + 数式 WHY 型 で先行確定、3 例目認定の前提整備)
- [ ] (中規模 v1.1) #174 navbar polish set / #177 calorie_advice 改善 / #178 /privacy マトリクス化 / #291 クレジット枯渇通知 — 別セッション判断

---

## How to apply

- **「Issue を減らしたい」 指示の機械化路線**: 軽量 3 連 (#176 → #175 → #190) を 1 セッション 3 PR ペースで close → Issue 数の可視的削減 (= 純減 2 件、起票分の正直記録)
- **PR body の `Closes #N` キーワード忘れ早期発見**: PR #299 で漏れ発覚 → `gh issue close N --comment "PR #X でマージ完了"` で手動リカバリ。次回 PR body 草稿時にチェックリスト確認 (= 既存運用反復、PR #301 + #302 では明示済 + 自動 close 成功)
- **meta タグ宣言 + CSS env() 補正は 2 PR で 1 機能完成パターン**: 後輩には「meta タグを追加した時は CSS 側のペアリングを必ず同時 PR で出す」 を初手で教えると Issue 起票の往復が 1 回減る (= メタ教訓 1 例目、Issue #303 が 2 例目候補)
- **Issue 本文の網羅指示と PR 実装範囲の差分は判断ログで担保**: PR #302 で Issue #190 が「navbar + footer + 危険ゾーン」 を網羅指示 → 本 PR は navbar のみで `Closes` する判断を Issue #190 コメントで明示。memory `feedback_issue_as_decision_log.md` の運用例
- **学び 36 サブカテゴリ拡張は定義明文化が先**: 3 例目認定を急ぐと「実は別物 2 種類が混ざってた」 と後で分解が必要、memory 整理 PR で定義固定 → 過去 PR を逆引き分類の順 (= 不発閾値 3/5 例事前確定ルール (Day 13 #294) の守り方)
