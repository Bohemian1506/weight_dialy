# Day 14 開発ログ (2026-05-12、v1.1 タグ Issue 着手シリーズ 1/N (= #176 OneTimeLoginToken 運用整備 完了))

day-13-4 (= リファクタ Tier 1 大物 #2 縮小完了) からバトンタッチ。局長指示「ISSUE を減らしたい」 = open Issue 20 件を v1.1 タグ 7 件着手から減らす方針確定 → 軽量 3 連 (#176 → #175 → #190) 順。本セッションは 1/3 = Issue #176 (= OneTimeLoginToken 運用整備、Phase 3 OAuth ブリッジ工事痕) 完了。

**Day 14 達成サマリ**: 1 PR (= #299) マージ + 1 Issue (= #176) close + 3 者並列レビュー指摘 7 件全件吸収 (= 軽量 Issue 1 PR ルール 20 例目連続達成) + 学び 36 サブカテゴリ拡張候補 (= コード内物理保存型 1 例目観測)。

---

## 🎯 Day 14 の目標

1. open Issue 20 件 → 着実に減らす (= v1.1 タグ 7 件着手から)
2. 軽量 3 連 (#176 → #175 → #190) を順に close
3. 大規模 / 中規模 v1.1 Issue (= #174 / #177 / #178 / #291) は別セッションで判断

---

## 🏆 達成したこと

### マージ済み PR (= 1 本)

| PR | Issue | 内容 |
|---|---|---|
| #299 | #176 | feat(ops): OneTimeLoginToken GC ジョブ + auto_login Cache-Control 整備。**+106/-1 行 / 7 ファイル**。Phase 3 OAuth ブリッジ用 `OneTimeLoginToken` (= TTL 30s、`/auto_login` で 1 回消費) の運用整備。(A) `CleanupOneTimeLoginTokensJob` 新設 (`expires_at < 1.day.ago` の `delete_all` を Solid Queue recurring `at 4am every day` で日次実行) + (B) `SessionsController#auto_login` に `Cache-Control: no-store` (= Turbo Drive prefetch 予防) 1 行追加。3 者並列レビュー指摘 7 件 (= **🟡 軽微 3 件 (= `expires_at` インデックス追加 + Cache-Control 慣用形 `response.cache_control[:no_store] = true` + spec 境界値テスト `freeze_time` 適用) + 🟢 提案 4 件 (= recurring.yml 語順統一 + `subject(:job)` → `let(:job)` + Cache-Control spec 補足コメント + job class に単純化判断コメント 1 行)**) を **全件本 PR 吸収** = **軽量 Issue 1 PR ルール 20 例目連続達成** (= Day 13-4 19 例目候補確定 + 本 PR 続伸)。`Closes` 自動 close は PR body に書き忘れ → 手動 `gh issue close 176` で対応 (= 副次知見)。33 spec examples / 0 failures / 85 files rubocop / 0 offenses。新規 migration 1 件 (= `add_index :one_time_login_tokens, :expires_at`) |

### close した Issue (= 1 件)

- **#176** (= v1.1: OneTimeLoginToken 運用整備) — PR #299 で close

### 起票した Issue (= 0 件)

---

## 🧠 教訓ハイライト (= 1 件、本日観測候補)

### 学び 36 サブカテゴリ拡張候補: コード内物理保存型 (= Issue 仮説 → PR 確定の判断理由をコメントとしてコードに残す) 1 例目

**前提**: memory `feedback_self_proposal_relativization.md` の 3 サブカテゴリ (= 自己完結型 + 学び 36 外部触媒型 + memory 整理 PR 単独) は Day 12-2 で確定済。

**本日新規観測**: PR #299 の `CleanupOneTimeLoginTokensJob` で、Issue 本文の `expired_or_used.where(created_at < 1.day.ago)` 案を実装時に `expires_at < 1.day.ago` 一本に simplification した。strategic-reviewer 論点 2 で「**この判断を PR body だけでなくコード内コメントとして物理的に残すと、後輩が PR diff だけで判断ロジックを拾える**」 と指摘 → 該当行に 1 行コメント追加で吸収:

`# (Issue #176 では expired_or_used scope 案だったが、TTL 30s なら expires_at 一本で網羅できるため単純化)`

**仮説**: 「Issue=仮説 / PR=確定」 ルールのコード内物理保存型 = 既存 3 サブカテゴリの 4 つ目の派生軸候補。1 例目観測のため確定保留 (= 3 回観測ルール、Day 11-3 で確立)。次回観測時に memory `feedback_self_proposal_relativization.md` のサブカテゴリ追記を検討。

---

## 📊 統計

- マージした PR: 1 本
- close した Issue: 1 件
- 起票した Issue: 0 件
- spec: 33 examples / 0 failures
- rubocop: 85 files / 0 offenses
- 教訓: 1 件 (= 観測 1 例目候補、確定保留)

---

## 🎯 残タスク

- [ ] **#175** Phase 3 cleanup set (= assetlinks.json 物理削除 + Mobile Chrome bypass 整理、軽量 3 連 2/3)
- [ ] **#190** safe-area-inset 補正 (= ノッチ / island 端末で navbar 欠け回避、軽量 3 連 3/3)
- [ ] マージ後 24h 以内に Solid Queue ログで `cleanup_one_time_login_tokens` 実発火時刻確認 (= TZ 検証、strategic 論点 1 由来)
- [ ] (中規模 v1.1) #174 navbar polish set / #177 calorie_advice 改善 / #178 /privacy マトリクス化 / #291 クレジット枯渇通知 — 別セッション判断

---

## How to apply

- **「Issue を減らしたい」 指示の機械化路線**: 軽量 3 連 (#176 → #175 → #190) を 1 セッション 1 PR ペースで close → Issue 数の可視的削減
- **PR body の `Closes #N` キーワード忘れ早期発見**: 本日 PR #299 で漏れ発覚 → `gh issue close N --comment "PR #X でマージ完了"` で手動リカバリ。次回 PR body 草稿時にチェックリスト確認 (= 既存運用反復)
- **コード内物理保存型 1 例目観測**: 「Issue=仮説 / PR=確定」 ルールをコード内コメントで残す = 学び 36 のサブカテゴリ拡張候補。次回観測で確定検討
