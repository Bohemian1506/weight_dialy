# Day 8 開発ログ (2026-05-06、発表会当日朝)

GW 7 日目、発表会当日。Day 7 (= 5/5) で **子 1-5a (= MVP) 完成** + **子 6 で 4 ブロッカー連鎖** + **Phase 2a/2b (AssetLinks) 沼ハマり → AssetLinks は Custom Tabs 内 callback 不対象と確定 → Phase 3 (= `@capacitor/browser` plugin) が明朝必須** で寝落ちした翌朝。本日は **発表会まで残り 10h** の状況下で **Phase 3 実装 → 3 者レビュー → ngrok smoke test → Render デプロイ → 実機検証 → AssetLinks 横取り障害発覚 → 緊急 fix → 完走** という濃密な 1 日。**Phase 3 設計の前提が実機検証で部分的に崩れる** という Day 7 学び 20 のさらなる更新を経験 (= 学び 21 として確立)。最終的に **Capacitor アプリ内で Google OAuth が cookie 分離問題を超えて完走、ホーム画面ログイン状態反映** に到達、**子 6 (Issue #40 / #125) 完走** = **Issue #40 B スコープのほぼ全てを発表会前に達成**。

セッションの戦略テーマ: **「Auth0 公式 quickstart の業界標準パターンを実装で証明する」+「ngrok hybrid smoke test で Google Console 設定変更ゼロのまま Capacitor 側を先行検証」+「実機検証で前提が崩れた時の即応 fix」**

---

## 🎯 Day 8 の目標

1. **Phase 3 (= `@capacitor/browser` + one-time token + custom URL scheme deep link) 実装** (= 子 6 完走の鍵、Auth0 quickstart 由来の業界標準)
2. **3 者並列レビュー** (= code/strategic/design、PR 規模に関わらず必ず通す原則)
3. **ngrok smoke test** で Capacitor 側ロジック先行検証 (= Google OAuth Console は触らず `redirect_uri_mismatch` までで止める hybrid 戦術)
4. **本番デプロイ後の実機 OAuth 完走** (= 子 6 = Issue #40 B スコープ最終ピース)
5. **発表会フォーム提出** (= URL / privacy / terms 提出)
6. **発表会 19:00 🎯**

---

## 🏆 達成したこと (= 計 2 PR + 子 6 完走)

### マージ済み PR (= 2 本)

| PR | Issue | 内容 |
|---|---|---|
| #153 | #125 子 6 | feat: Phase 3 — `@capacitor/browser` + one-time token で OAuth cookie 分離問題を構造解決 (= Stimulus intercept + Browser.open + 中継ページ + OneTimeLoginToken + custom scheme deep link、Auth0 quickstart パターン、3 者レビュー反映済) |
| #154 | #125 子 6 | fix: AssetLinks intent-filter 削除 (= 実機検証で OAuth callback URL を `appUrlOpen` 経由で WebView 転送 → state 不整合で「キャンセル」障害発覚、custom scheme 一本に統一) |

### close した Issue
- **#125 子 6 (= Capacitor 実機 E2E)** — 本日完走、Issue #40 B スコープのほぼ全達成

### 起票した Issue (= v1.1 候補、メモのみ)
- `public/.well-known/assetlinks.json` 物理削除 cleanup
- token GC ジョブ (= TTL 30s でも数日で堆積、Solid Queue で `expired.delete_all`)
- Mobile Chrome bypass 整理 (= ApplicationController の Phase 3 工事痕)
- `auto_login` に `Cache-Control: no-store` (= Turbo Drive prefetch 予防)

---

## 🧠 教訓ハイライト (= 1 件本日確立、Day 7 学び 20 の更新)

### 学び 21: AssetLinks の実機挙動は端末ガチャ、custom URL scheme 一本が最も安定

Day 7 学び 20 では「AssetLinks は Custom Tabs 内 callback 不対象」と確定したが、本日 Phase 3 実装後の実機検証 (Torque G6 / Android API 35) で **AssetLinks intent-filter が Custom Tabs 内 OAuth callback URL を横取りして発動** した。具体的には Custom Tabs が `https://weight-dialy.../auth/google_oauth2/callback` に navigate しようとした瞬間、`autoVerify=true` の intent-filter が OS レベルで横取りし、Capacitor アプリに deep link → Rails の `sessions#create` (= Phase 3 ブリッジ核心) に到達せず WebView 側で処理しようとして state 不整合で失敗。

**端末 / Android バージョン / AssetLinks verify 完了タイミング等の差で「動いたり動かなかったり」する**。つまり「AssetLinks は動かないからフォールバック実装」も「AssetLinks 前提の seamless 設計」も両方ガチャ。設計依存先として不確実すぎる。

→ **解決策**: AssetLinks intent-filter を完全削除、custom URL scheme (= `com.weightdialy.app://`) 一本で完結する設計にする。custom scheme は Android の intent-filter 仕様上、ハンドラアプリが 1 つあれば必ず発動する (= http(s) ベースの App Links と違って verify 不要、システムが scheme で routing する)。

How to apply:
- ハイブリッドアプリで OAuth する場合、AssetLinks (Universal Links / App Links) を deep link 経路として使うのは避ける
- custom URL scheme + one-time token (= server side で発行、TTL 30s + 1 回限り消費) を使うのが業界標準で安定 (= Auth0 / Firebase / Cognito モバイル SDK が全部この形)
- Android Manifest で `<data android:scheme="@string/custom_url_scheme" />` の intent-filter 一本だけで済む

---

## 🔥 つまずき / 学び (= 本日 6 件)

### 1. Brakeman の false positive で CI 失敗 (= 1 PR で発覚)

PR #153 で `redirect_to "com.weightdialy.app://oauth_callback?token=#{ott.token}", allow_other_host: true` が Brakeman の `Possible unprotected redirect` (Weak confidence) で flag → CI scan_ruby が FAILURE。実際は redirect URL 全体が固定文字列 + サーバ生成 token のみで安全だが、static analysis の data flow 解析が `OneTimeLoginToken#issue!(user: user)` の引数 user を「外部由来」と判定。

→ 解決: `config/brakeman.ignore` を JSON で書いて fingerprint で除外。fingerprint は `bin/brakeman --no-pager -f json` の出力から `warnings[].fingerprint` を取得。`note` フィールドに「なぜ false positive か」を必ず記載 (= 後輩 / 未来の自分のため)。

How to apply:
- Brakeman 警告は「警告内容を読む → 本当にリスクか判定 → false positive なら ignore + note 必須」
- ignore せずコードを変えて警告回避もアリだが、明らかな false positive を「Brakeman を黙らせるための無意味な refactor」は避ける

### 2. ngrok hybrid smoke test (= Google Console を触らず Capacitor 側を検証する戦術) が成功

strategic-reviewer が「ngrok で事前検証推奨」と提案したが、Google OAuth Console に ngrok URL を追加するのは「設定の往復 (= 追加 → テスト → 削除し忘れリスク)」で 15-30 分余計にかかる。一方、何も検証せず Render 直行は「Day 7 4 ブロッカー連鎖の再発リスク」。

→ 採用した hybrid 戦術 (= 局長判断「c で行きましょう」):
- Google Console は変更せず、ngrok URL での `redirect_uri_mismatch` エラーまでを検証範囲とする
- これで **Capacitor 側 (Stimulus intercept / Browser.open / Custom Tabs / toolbarColor / 中継ページ / OmniAuth POST → Google 到達)** は全部検証できる
- OAuth 完走 → custom scheme deep link → `/auto_login` の最終フェーズだけは本番 URL で実機一発検証

結果: hybrid smoke test で「オレンジ Custom Tabs + 中継ページスピナー + Google で `redirect_uri_mismatch`」を確認、Capacitor 側ロジック完璧と判断、安心して Render 本番投入。

How to apply:
- 外部認証サービスを使う実装の事前検証で「サービス側設定を触りたくない」場合、エラー画面まで到達することで部分検証する設計の有用性
- 全部一気に検証しようとすると検証コストが高くつく、段階的に切り分ける

### 3. Java 8 (32-bit JRE) でビルド失敗 → JDK 21 切替

局長手元の `./gradlew assembleDebug` が「Could not reserve enough space for 1572864KB object heap」で失敗。原因は `C:\Program Files (x86)\Java\jre1.8.0_481\bin\java.exe` (= Java 8、32-bit JRE) が使われていた。Capacitor 8.x / Android Gradle Plugin 8.x は **JDK 17 以上が必須**、32-bit JRE はヒープ ~1.5GB が上限。

→ 解決: Android Studio 内蔵の JBR (JetBrains Runtime) 21 を Gradle JDK に設定 (Settings → Build, Execution, Deployment → Build Tools → Gradle → Gradle JDK)。

How to apply:
- Android 系開発 (Capacitor / Flutter / React Native 含む) は JDK 17+ 必須が現代の前提
- Android Studio 内蔵 JBR は最も confidence 高い選択肢、外部 JDK install 前にまずこれを試す
- 32-bit JRE は今や ほぼ全開発で支障あり、絶対に環境から退役させる

### 4. WSL ↔ Windows コピー運用の同期不足 (= 5 ファイル + node_modules)

ユーザー手元の Capacitor Android プロジェクトが `\\wsl.localhost\...` 直接開きで Android Studio が「Write Permissions Issue」エラーを出すため、WSL の `~/workspace/weight_dialy/android/` を `C:\dev\weight_dialy_android\` に手動コピー運用。Phase 3 (PR #153 マージ後) のテストで、Windows 側コピーが **Phase 2a より前の状態** (= `@capacitor/app` も `@capacitor/browser` も未登録) と判明。同期忘れの結果、APK 内 server.url が古いままで「production weight-dialy.onrender.com」を見ていた → 「これ ngrok 反映されてない」事象。

cap sync が触る同期必要ファイル (= 完全リスト):
1. `android/app/src/main/AndroidManifest.xml`
2. `android/app/src/main/assets/capacitor.config.json` (= `server.url` / `allowNavigation`)
3. `android/app/src/main/assets/capacitor.plugins.json` (= JS ↔ Native bridge 定義、**忘れがち**)
4. `android/capacitor.settings.gradle` (= plugin 登録 `include ':capacitor-browser'` 等)
5. `android/app/capacitor.build.gradle` (= 依存 `implementation project(':capacitor-browser')`)
6. `node_modules/@capacitor/<plugin>` (= plugin 本体、相対パス参照)

特に `capacitor.plugins.json` は最初の 5 ファイル同期では気付かず、「@capacitor/browser plugin が JS bridge から見えない」状態で 1 ラウンドハマった。

How to apply:
- Capacitor 系で「plugin が動かない」「server.url が古い」症状の時は cap sync 出力 6 種全部の同期確認
- WSL ↔ Windows 二重管理は同期ミスの温床、可能なら片方に統一 (= devcontainer の Linux 内で完結 + Android Studio も Linux 側、または Windows 側完結) するのが理想
- 二重管理続けるなら同期スクリプト (= `Copy-Item` のバッチ化) を作る

### 5. capacitor_start.html.erb の CSRF token テストで test env 仕様にハマる

PR #153 の RSpec で「authenticity_token が form に含まれること」を assert しようとしたが、Rails test 環境はデフォルトで `ActionController::Base.allow_forgery_protection = false` のため form に token が出ない。

→ 解決: spec 内で一時的に `allow_forgery_protection = true` にして検証、`ensure` で必ず元に戻す:

```ruby
it "includes CSRF authenticity token under production-like forgery protection (= OmniAuth POST 必須)" do
  original = ActionController::Base.allow_forgery_protection
  ActionController::Base.allow_forgery_protection = true
  begin
    get capacitor_oauth_start_path
    expect(response.body).to match(/name="authenticity_token"/)
  ensure
    ActionController::Base.allow_forgery_protection = original
  end
end
```

How to apply:
- production 仕様の挙動を test で検証する時、test env 設定差を意識する
- グローバル状態を変更する spec は `ensure` で必ず復元 (= 他 spec への汚染回避)

### 6. AssetLinks 横取り障害 (= 学び 21 の発覚経緯)

PR #153 (Phase 3) マージ後、実機 (Torque G6) で OAuth ログイン試行 → Custom Tabs オレンジ起動 ✅ → 中継ページ ✅ → Google ログイン画面 ✅ → アカウント選択 ✅ → 「Google ログインがキャンセルされました」alert で本番ホーム画面に戻る (= 失敗) という現象。

ログ証跡:
```
2026-05-06 07:54:43.918 Capacitor/AppPlugin: Notifying listeners for event appUrlOpen
URL: https://weight-dialy.onrender.com/auth/google_oauth2/callback?state=...&code=...
```

期待は `com.weightdialy.app://oauth_callback?token=XXX` を `appUrlOpen` で受信、実際は OAuth callback URL そのものを受信 → capacitor_init.js の Phase 2a 互換 path で WebView ロード → OmniAuth state 不整合 (= state cookie は Custom Tabs 側にあり WebView は fresh session) → /auth/failure → 「キャンセル」alert。

→ 解決: PR #154 で AssetLinks intent-filter 削除 + capacitor_init.js の Phase 2a 互換 path 削除。custom scheme 一本に統一。

How to apply:
- 実機検証は最終確認として必ず行う (= ngrok smoke test で「Capacitor 側 OK」と判断したが、実機の AssetLinks 挙動は smoke test では現れない)
- 学び 20 で確定した「AssetLinks 不発」の前提が学び 21 で覆される、**実機は仮説をひっくり返す**
- 障害発覚時は logcat の URL を必ず確認 (= 何が `appUrlOpen` に来ているかで原因が一発判明)

---

## 🤝 ユーザー (= 本人) の判断ハイライト

1. **「1 からで大丈夫」** (Phase 3 着手判断、迷いなく)
2. **「OK」「c で行きましょう」「OK ですがログインはしきれてなくて大丈夫ですか?」** (= 各段階で確認しつつ前進する慎重さ + 設計理解の深さ)
3. **「ハイブリッドで行きましょう」** (= ngrok hybrid smoke test 採用、コスト効率の判断力)
4. **「マージもしちゃってください」** (= CI 通過後の即マージ判断、authorization の明示)
5. **「過去のいきさつって見れます?」** (= セッション中の整理確認、メタ的に俯瞰)
6. **「一歩ずつ進んでる感じがしていいですね」** (= 障害連発でも前進感を維持するメンタル管理力)
7. **「ログインできました!」** (= 完走確認、達成宣言)

---

## 📊 統計

- マージした PR: **2 本** (= #153 Phase 3 主幹実装 + #154 AssetLinks 削除緊急 fix)
- close した Issue: **1 件** (= #125 子 6 = Capacitor 実機 E2E)
- 全体 spec: 431 → **515 examples** (= +84、Phase 3 関連 35 + Day 7 後追い分の取り込み等)
- 教訓: **1 件** (= 学び 21、Day 7 学び 20 の更新版)
- つまずき / 学び: **6 件** (= Brakeman false positive / ngrok hybrid smoke test / Java 8 / WSL-Windows 同期 / CSRF test 仕様 / AssetLinks 横取り)
- v1.1 候補 / 別 Issue 起票: **4 件** (= assetlinks.json 物理削除 / token GC / Mobile Chrome bypass 整理 / Cache-Control: no-store)
- セッション時間: **約 4 時間** (= 朝〜昼、発表会まで残り ~5h 確保)

---

## 🎯 残タスク (= ユーザー本人作業)

### 5/6 朝〜午後 (= 発表会前)
- [ ] 発表会フォーム提出 (= URL: `https://weight-dialy.onrender.com`、`/privacy`、`/terms`、問い合わせ先 `weightdaily3@gmail.com`)
- [ ] 本番動作の最終ヘルスチェック (= ログイン → 同期 → AI 提案 → ホーム画面表示までの golden path)

### 5/6 19:00
- [ ] **発表会 🎯**

### 発表会後 v1.0 / v1.1
- [ ] 子 5b (= WorkManager 自動同期、~3-5h)
- [ ] 子 7 (= APK ビルド + sideload 手順、~1h)
- [ ] `public/.well-known/assetlinks.json` 物理削除 cleanup (= 1 PR)
- [ ] token GC Solid Queue ジョブ (= 1 PR)
- [ ] Mobile Chrome bypass 整理 (= 1 PR)
- [ ] `/auto_login` `Cache-Control: no-store` (= 1 PR)
- [ ] 派生 polish 8 件 (= Day 7 残: #128 splash / #131 /privacy HC / #134 UI 微調整 / #138 Webhook UX / #143 SNS OAuth / #144 HC 視認性 / #145 FOUT / #150 deep link ダイアログ誤選択)

---

## How to apply

- **次セッション (= 発表会後想定)**: 本ドキュメントを最初に読む、v1.1 計画の起点にする
- **ハイブリッドアプリ × OAuth**: `feedback_hybrid_app_oauth_pattern.md` (= 学び 19-21 の集約) を参照
- **新規外部認証統合**: ngrok hybrid smoke test 戦術 (= Google Console 等を触らず error 到達まで検証する) を再利用
- **WSL ↔ Windows 二重管理プロジェクト**: cap sync で触られる 6 種ファイル全部を同期チェックリスト化、または devcontainer で完結する一元管理に変更検討
- **Brakeman false positive**: `config/brakeman.ignore` JSON 化、`note` フィールド必須記入の運用継続
- **発表会後 v1.1 着手フロー**:
  1. memory `project_day8_summary.md` (= 本日新設予定) を最初に読む
  2. 残 polish 8 件 + cleanup 4 件を別 Issue で個別処理
  3. v1.1 中核機能 (= 子 5b WorkManager + 子 7 APK 配布) を並行開発
