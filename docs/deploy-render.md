# デプロイ環境 (Render Free Tier)

> 元は README.md の 11 章だったが、技術ドキュメントとして長くなったため `docs/deploy-render.md` に分離 (= 後輩が必要な時だけ参照する技術詳細書)。

## 採用: Render (Free Tier)

| 候補 | 無料枠 | 半日完了 | 採用 |
|---|---|---|:---:|
| **Render** | ⭕ Web Service Free + Postgres Free | ⭐⭐⭐⭐⭐ | ✅ |
| Kamal + さくら VPS / Hetzner | ❌ VPS 月額必須 | ⭐⭐ | (将来) |
| Fly.io | △ Trial credit 制 (変動あり) | ⭐⭐⭐ |  |

**採用根拠 4 点**:

1. **完全無料枠** で MVP / 発表会用途を完結できる (スクール期間中の費用ゼロ)
2. **半日でデプロイ完了可能** (= Day 5 の本番デプロイタスクを後ろ倒さない)
3. **Render の運用経験あり** (= 詰まり時間の最小化)
4. **将来の DB 分離運用への移行が楽** (= Free Tier では Solid Trifecta を 1 DB に同居させるが、有料化したら `database.yml` の url を切り替えるだけで Rails 8 標準の 4 DB 構成に戻せる、後述参照)

## 構成

```
[Render Web Service: weight-dialy]   ← Ruby 3.4.9 + Rails 8.1.3
            │
            ├─ buildCommand: bin/render-build.sh
            │      (bundle install / assets:precompile / db:prepare)
            │
            └─ startCommand: bundle exec rails server -p $PORT -e production
                                           │
                                           ▼
[Render Postgres Free: weight-dialy-db]
└── app_production
    ├── users / step_records / webhook_deliveries     ← アプリデータ
    ├── solid_cache_entries                           ← Solid Cache 同居
    ├── solid_queue_*                                 ← Solid Queue 同居
    └── solid_cable_messages                          ← Solid Cable 同居
```

Infrastructure as Code として `render.yaml` でこの構成を定義 (= Render Dashboard で「New Blueprint」→ リポジトリ指定で自動構築される)。

## Solid Trifecta を 1 DB に同居させた判断 (= Free Tier 制約)

**Rails 8 デフォルト**: `primary` / `cache` / `queue` / `cable` の 4 つの database に分離 (負荷分離 + vacuum 影響回避が目的)。

**今回**: Render Postgres Free Tier は 1 インスタンス 1 database のため、**全部を `app_production` に同居** させる構成を採用 (`config/database.yml` の production セクション参照)。

- テーブル名は prefix (`solid_*`) で名前空間が分かれているので衝突しない
- 個人開発 / 小規模 (< 数千ユーザー) では負荷分離の効果が誤差レベル
- DHH も「最初は same-DB で十分、後から分離」を推奨

**有料プラン化時の移行パス** (引き返せるパス):
- Render UI で Postgres を 3 つ追加 (cache / queue / cable 用)
- `database.yml` の各セクションの url を新 ENV (`CACHE_DATABASE_URL` 等) に切替
- `bin/rails db:migrate:cache` 等で新 DB に Solid テーブルを作成
- `migrations_paths` の構造は同居時も維持しているため、移行時に追加作業ゼロ
- 所要時間 ~1.5 時間

## 初回デプロイ手順

1. **ローカルで production-specific credentials を編集** (Google OAuth client_id / secret を入れる)
   ```bash
   # VS Code 派 (推奨):
   EDITOR="code --wait" bin/rails credentials:edit -e production
   # vim 派:
   EDITOR=vim bin/rails credentials:edit -e production
   ```
   - 生成される `config/credentials/production.yml.enc` (= 暗号化済み) は **commit する**
   - 生成される `config/credentials/production.key` (= 復号 key) は **`.gitignore` で除外、絶対 commit しない**
   - 編集 → 保存 → 別ブランチで commit & push & PR (= main 直 push はガードでブロックされる)
2. **`config/credentials/production.key` の中身を控える** (= デプロイ後の Render 環境変数で必要)
3. **Google OAuth Console** で本番 redirect URI (`https://<your-render-domain>/auth/google_oauth2/callback`) を許可リストに追加
4. **Render Dashboard** で `New Blueprint` → 本リポジトリを指定 → `render.yaml` が自動検出される
5. **環境変数を設定** (Render Dashboard → 該当 Service → Environment):
   - `RAILS_MASTER_KEY` = ローカルの `config/credentials/production.key` の中身
   - `APP_HOST` = Render が割り当てたドメイン (例: `weight-dialy.onrender.com`)
6. **デプロイ完了後**: ブラウザで `https://<your-render-domain>/` にアクセス → 200 OK 確認
7. **Google ログイン** → ダッシュボード遷移確認

## Sleep 対策 (Free Tier の cold start 回避)

Render Free Tier は **15 分非アクセスで sleep** → 初回アクセス cold start ~30 秒。
発表会で致命的なため、**GAS (Google Apps Script) で 10 分間隔の warmup ping** を仕込む。詳細は Issue #61 で運用設定済み。

**当日朝の必須チェック**: 発表会当日朝に **GAS の実行ログ** (Apps Script 画面の「実行数」) を確認し、最後の ping が想定通り 10 分以内に動いていることを目視で確認する。warmup が止まっていると iPhone Safari のデフォルト 60 秒タイムアウトに対し cold start 25-40 秒の幅が問題になる可能性がある。
