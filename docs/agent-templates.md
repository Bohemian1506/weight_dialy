# エージェント横断テンプレート

複数のサブエージェントをまとめて動かすときのコピペ用テンプレート集。「3 者並列レビュー」「実装 → テスト引き継ぎ」など、複数エージェントが絡む横断パターンを扱う。各エージェント単体の呼び方は `.claude/agents/<name>.md` の「依頼時に渡してほしい情報」を参照。

> **初めて読む場合の順序**: `.claude/agents/rails-implementer.md` → `test-writer.md` → 本ドキュメント。これでフロー全体の骨格が掴める。

---

## 3 者並列レビュー (code-reviewer + strategic-reviewer + design-reviewer)

weight_dialy の中核運用フロー。Day 2 の 6 PR 全てで使用し、再現性を確認済み。

### 起動タイミング

| タイミング | 必須度 |
|---|---|
| PR 作成直後 (Blocker を 1 ラウンド目で全部出す) | 必須 |
| レビュー反映後の再レビュー (セキュリティ / アクセシビリティ系の Blocker があった場合) | **必須** |
| その他の修正後 | 任意 |

> **教訓** (PR #12 / Day 2): Session Fixation のような「設計時に想定しないと出ない罠」は再レビューで担保する。1 ラウンド Go したからといって反映後にスキップしない。

### 起動方法

**1 メッセージ内で 3 つの Agent ツールコールを並列実行する**。順番に呼ぶと待ち時間が積み上がる。

```
Agent(subagent_type="code-reviewer", description="PR #XX 細部レビュー", prompt=<下記テンプレ>)
Agent(subagent_type="strategic-reviewer", description="PR #XX 戦略レビュー", prompt=<下記テンプレ>)
Agent(subagent_type="design-reviewer", description="PR #XX デザインレビュー", prompt=<下記テンプレ>)
```

### 共通プロンプト雛形

3 者共通で渡す枠を作り、各エージェント向けの観点だけ差し替える。

```
PR #XX のレビューをお願いします。

## 概要
<1〜2 行で「何を変えたか」>

## 関連 Issue
#YY

## 変更ファイル
- app/...
- spec/...
- (UI 変更の場合) app/views/...

## 自信が無い / 議論したい所
- ...
- ...

## 観点 (各エージェントごとに差し替え)

### code-reviewer 向け
- セキュリティ重点 (該当する場合: HMAC / CSRF / Strong Parameters / 認可 など)
- N+1 / Rails 慣習で見て欲しい所

### strategic-reviewer 向け
- フェーズ: Day N / 締切まで Z 日
- 設計判断: 採用案 + 検討して捨てた案
- 懸念ポイント (スコープ / 教材性 / 将来拡張)

### design-reviewer 向け (UI 変更がある場合のみ)
- 変更画面: <ルート>
- 想定シーン (デモ / 通常利用 / オンボ)
- モバイル必須か
```

### 再レビュー時のフォーマット (Day 2 で確立)

修正コミットに **「指摘との対応関係」をカテゴリ別に列挙** する。後で読む人 (自分含む) の負担が劇的に下がる。

```
PR #XX のレビュー指摘を反映しました。再レビューお願いします。
修正コミット: <SHA>

[code-reviewer] 反映:
- 🚨 <Blocker 内容> → ファイル:行
- ⚠️ <Should fix 内容> → ファイル:行

[strategic-reviewer] 反映:
- 🟡 <設計見直し内容> → 採用案 / 反映理由

[design-reviewer] 反映:
- 🚨 <Blocker 内容> → ファイル:行
- 💡 <Nit を採用した場合> → ファイル:行

[未反映 / 別 Issue 化したもの]
- <内容> → 理由 (スコープ外 / 後続 Issue で対応 など)
```

---

## rails-implementer → test-writer 引き継ぎ

実装完了後、テスト追加を依頼するときの定型パターン。

### 引き継ぎ要点

rails-implementer の **完了報告がそのまま test-writer の入力になる** よう設計されている。具体的には:

| rails-implementer 完了報告 | → test-writer に渡す情報 |
|---|---|
| 変更したファイル一覧 | テスト対象ファイル |
| 主な実装意図 | テスト観点の判断材料 |
| 残タスク・懸念点 | 「自信が無い箇所」 |
| レビュアーへの引き継ぎポイント | テストで重点的に検証する箇所 |

完了報告を貼り付けた上で、追加で **テスト観点 (model / request / system のどれが必要か)** だけ明記すれば足りる。

---

## api-researcher → rails-implementer 引き継ぎ

調査結果を実装に渡すときは、**api-researcher のレポートをそのまま実装依頼の「既知の制約」セクションに貼り付ける**。

特に活きる項目:
- **サンプルコード**: rails-implementer が「最小動作例から拡張する」スタートラインになる
- **ハマりポイント**: 「既知の制約」として実装前に伝えると事故を防げる
- **想定実装コスト**: rails-implementer に渡す「締切」の現実性チェックに使う

---

## 関連ドキュメント

- 各エージェント単体の依頼テンプレ: `.claude/agents/<name>.md` の「依頼時に渡してほしい情報」
- 運用フロー全体像: `docs/dev-log/day-2.md` の「📝 Day 2 で確立した運用フロー」セクション
- プロジェクト方針: `memory/project_weight_dialy.md`
