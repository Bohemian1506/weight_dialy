# Day 1 開発ログ (2026-04-30)

GW 開発期間の初日。プロジェクト立ち上げから AI 支援開発のメタレイヤー整備まで。

---

## 🎯 Day 1 の目標

1. プロジェクトの基本方針を対話で固める
2. Rails 8 雛形を Dev Container で生成
3. Google OAuth・データ取込経路など主要技術選定
4. AI 支援開発のメタレイヤー (CLAUDE.md + サブエージェント) を整備
5. GitHub への公開と最初の PR 起票

---

## ✅ 達成事項

### プロジェクトの方向性確定
- **ターゲット像**: ジムも筋トレもしない通勤通学カジュアル層
- **コンセプト**: 「日常の小さな勝ちを自動で拾って褒める」
- **データ取込経路 (優先順)**:
  1. Apple Shortcuts → Webhook (iPhone カジュアル層・メイン)
  2. デモモード (サンプルデータ閲覧)
  3. 手動 ZIP アップロード (Android フォールバック)
  4. Strava OAuth (余裕枠・教材性のため)
- **締切**: 2026-05-06 19:00 (スクールミニアプリ発表会)

### 技術スタック確定
- Ruby 3.4.9 / Rails 8.1.3
- PostgreSQL 16.1 (Dev Container)
- Tailwind CSS 4 + daisyUI (Day 2 で導入予定)
- Hotwire (Turbo + Stimulus) + Importmap
- Solid Cache / Solid Queue / Solid Cable (DB ベース)
- Kamal (Day 5 でデプロイ判断)

### サブエージェント 6 体制
| エージェント | 役割 |
|---|---|
| `rails-implementer` | 実装担当 |
| `test-writer` | RSpec 担当 |
| `code-reviewer` | 細部レビュー (編集長) |
| `strategic-reviewer` | 戦略レビュー (副局長) |
| `design-reviewer` | UI / UX レビュー |
| `api-researcher` | 外部 API 調査 |

### コミット & PR
- **初回コミット** (`ea5d52f` on `main`): Rails 8.1.3 雛形
- **feat コミット** (`c4e6fc9` on `feature/claude-code-setup`): サブエージェント + ツール
- **PR #1**: Claude Code サブエージェント + Dev Container ヘルパー

---

## 🔥 遭遇したトラブルと解決

### トラブル 1: 「自動記録」を Web アプリで実現する経路の見直し

**症状**: 当初「Web アプリで歩行を自動記録」を目指したが、Web の制約上不可能と判明。

**経緯**:
1. ネイティブアプリで自動記録 → Web に方針変更 (Web の制約)
2. Google Fit API 想定 → 廃止済みと判明 (2024 年 5 月段階廃止)
3. Strava API メイン想定 → ターゲットがカジュアル層のため Strava 持ってない人多数と判明
4. **Apple Shortcuts → Webhook をメインに据える** へ最終転換

**学び**:
- 「自動記録」と一言で言っても、ターゲットによって最適な経路は全く違う
- API の生死は早めに公式情報で確認すべき (Google Fit のような大手 API でも廃止される)
- 「教材性」と「ターゲット適合性」は別軸で評価する

### トラブル 2: Antigravity で Dev Containers 拡張が動かない

**症状**: Google の AI IDE Antigravity で `Dev Containers: Reopen in Container` のコマンドが出てこない。

**原因**:
- Antigravity (および Cursor / Windsurf 等) は VS Code 派生 IDE だが、Microsoft の Remote 系拡張はライセンスや拡張マーケットの違いで使えないことがある
- Microsoft 公式 Marketplace の拡張は OpenVSX (派生 IDE が使う代替マーケット) には公開されていない

**解決**: VS Code 純正版に切り替えて Reopen in Container を実行。

**学び**:
- Microsoft Remote 系拡張 (Dev Containers / Remote-SSH / Remote-WSL) は VS Code 純正前提のものが多い
- AI IDE と Dev Container を組み合わせるには、(1) AI IDE 側のフォーク版を待つ、(2) VS Code 純正で開発、(3) ハイブリッド運用、いずれかの選択になる

### トラブル 3: json gem の native extension がロードできない (これが一番ハマった)

**症状**:
```
LoadError: cannot load such file --
  /home/vscode/.local/share/mise/installs/ruby/3.4.9/lib/ruby/gems/3.4.0/gems/json-2.19.4/lib/json/ext/parser.so
```

`bin/setup` が postCreateCommand で失敗。bundle install 自体は通っていたのに `parser.so` がロードできない。

**試行錯誤**:
1. **`bundle pristine json`** を実行 → 一度は成功、`bin/setup` は通る
2. **`bin/dev`** で起動しようとすると同じエラー再発
3. **`bundle pristine`** (全 gem 再ビルド) → それでも `bin/dev` でエラー
4. **`gem pristine json --version 2.19.4`** (RubyGems 直接) → 解決

**根本原因**:
- `bundle pristine` は Bundler 経由のリビルド
- `gem pristine` は RubyGems 直接のリビルド
- Ruby 3.4 + 新しい Bundler + mise の組み合わせで、Bundler のキャッシュ層が C 拡張のリビルド結果を正しく認識しない事象がある
- エラーメッセージ自体が `Try: gem pristine ...` を提案していた → **エラーメッセージの提案を素直に試すべきだった**

**学び**:
- `bundle pristine` と `gem pristine` は別物。両方試す価値あり
- LoadError でファイルパスが出るとき、まず `ls` でファイルの存在を確認する
- Ruby のエラーメッセージは具体的な解決コマンドを書いてくれていることが多い。読み飛ばさない

### トラブル 4: Docker Desktop の WSL 連携が無効だった

**症状**: WSL から `docker` コマンドが認識されない。

**原因**: Docker Desktop の WSL Integration が OFF。

**解決**: ユーザーが Docker Desktop を起動したらそのまま動いた。Settings → Resources → WSL Integration の確認手順は知っておくと良い。

### トラブル 5: ホスト (Claude Code) からコンテナ内コマンド実行

**課題**: Claude Code は WSL ホスト側で動くが、Ruby/Rails はコンテナ内にしかない。

**解決**: `script/run` ヘルパーを作成。要点:

```bash
# compose ラベルでコンテナ動的発見 (リビルドで名前変わっても追従)
CONTAINER=$(docker ps \
  --filter "label=com.docker.compose.project=app" \
  --filter "label=com.docker.compose.service=rails-app" \
  --format "{{.Names}}" | head -n1)

# mise の shim を PATH に通す (非対話シェルでは mise activate が走らないため)
docker exec -u vscode -w /workspaces/weight_dialy \
  -e PATH="/home/vscode/.local/share/mise/shims:..." \
  "$CONTAINER" bash -c "$*"
```

**学び**:
- mise / asdf 系のバージョンマネージャは `eval "$(mise activate bash)"` を `.bashrc` で読み込む方式が多い
- `docker exec` は非対話シェルなので `.bashrc` が読まれず PATH が通らない
- shim ディレクトリを直接 PATH に渡すと簡潔
- コンテナ名はラベルで動的発見する方が運用が楽 (リビルド・名前変更に強い)

---

## 📝 Day 1 の主な決定事項 (議事録)

| 論点 | 決定 |
|---|---|
| 開発コンテナ戦略 | Dev Container (`rails new --devcontainer`) |
| メイン言語 | Ruby on Rails (8.1.3) |
| データベース | PostgreSQL 16 |
| CSS | Tailwind 4 + daisyUI (Day 2) |
| JS | Importmap (esbuild / webpack 不使用) |
| ViewComponent | GW 中は見送り、Phase 4 で導入検討 |
| 認証 | Google OAuth (omniauth-google-oauth2 予定) |
| 取込メイン経路 | Apple Shortcuts → Webhook |
| Strava | 余裕枠で実装、メインから降格 |
| AI 食事判定 | GW 後送り |
| GitHub | public で公開 |
| ブランチ運用 | main 直コミット禁止、feature/* で PR ベース |
| サブエージェント | 6 体制 (担当 2 + レビュー 3 + 調査 1) |

---

## 🎓 後輩への学び (Take-aways)

このリポジトリを参考にする後輩向けに、Day 1 で得た知見:

1. **「何のアプリか」を最初に固める前に、技術選定をしない**
   ターゲット像を決めると、最適な API も技術スタックも変わる。

2. **公式 API の生死は最初に確認**
   「使えるはず」で進めると詰む。Google Fit のように大手でも廃止される。

3. **Dev Container は便利だが、IDE 互換性に注意**
   AI IDE (Antigravity / Cursor 等) と Microsoft 公式拡張の組合せはハマりやすい。

4. **エラーメッセージは丁寧に読む**
   `Try: gem pristine ...` のように解決策が書かれていることが多い。

5. **対話で「選択肢 → トレードオフ → 決定」を回す**
   後で読み返したときに、なぜその技術を選んだかが追える。

6. **AI 支援は最初にメタレイヤーを整える**
   サブエージェント・CLAUDE.md・hooks を最初に整備しておくと、以降の開発でレビュー観点や設計判断が一貫する。

---

## 📊 Day 1 終了時点の状態

- [x] Rails 8 雛形完成
- [x] Dev Container 起動成功
- [x] DB 作成 (`app_development` / `app_test`)
- [x] http://localhost:3000 で welcome 画面表示
- [x] サブエージェント 6 体制 + CLAUDE.md
- [x] GitHub public repo 作成 + PR #1 起票
- [ ] daisyUI 導入 (Day 1 後半 or Day 2 へ)
- [ ] RSpec 導入
- [ ] Google OAuth 設定

次は **`feature/add-daisyui`** ブランチで daisyUI のセットアップへ進む。
