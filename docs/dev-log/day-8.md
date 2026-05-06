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

## 🏆 達成したこと (= 計 27 PR + 子 6 完走 + Day 7 連鎖バグ 3 件 + 3 ステップ思想バグ 1 件 + 法務 Health Connect 対応 1 件 + Capacitor splash polish 1 件 + navbar 2 連 polish + Settings ポリシーリンク移動 1 件 + Webhook 422 文言 I18n 化 1 件 + banner_android UX ループ解消 1 件 + navbar X グループ 1 件 + 公開前最終 polish 4 件集約 1 件 + OGP 最小整備 1 件 + 動線リハ反映 polish 1 件 + OGP リッチ移行 1 件 + Favicon リッチ移行 1 件 + ログイン CTA 集約 (案 A 逆転) 1 件 + モバイル比率 + Web 下切れ予防 1 件 + AI カード flex + navbar mobile 1 件 + 0 歩警告 + navbar 左寄せ 1 件 + Android 利用ガイド README 1 件 + .sketch-btn nowrap + flex-shrink 1 件 + navbar ボタン縦位置微調整 1 件 + 初回 welcome モーダル 1 件 + v1.1 backlog 5 件集約)

### マージ済み PR (= 10 本)

| PR | Issue | 内容 |
|---|---|---|
| #153 | #125 子 6 | feat: Phase 3 — `@capacitor/browser` + one-time token で OAuth cookie 分離問題を構造解決 (= Stimulus intercept + Browser.open + 中継ページ + OneTimeLoginToken + custom scheme deep link、Auth0 quickstart パターン、3 者レビュー反映済) |
| #154 | #125 子 6 | fix: AssetLinks intent-filter 削除 (= 実機検証で OAuth callback URL を `appUrlOpen` 経由で WebView 転送 → state 不整合で「キャンセル」障害発覚、custom scheme 一本に統一) |
| #156 | – | fix: Health Connect 階段データ型を `flightsClimbed` に修正 (= 実機検証で `floorsClimbed` typo 発覚、@capgo/capacitor-health の API 名は米国流) |
| #157 | – | fix: Health Connect authorization 結果を `readAuthorized` ベースで判定に修正 (= `result?.granted` という存在しないプロパティを参照していたため、許可済でも常に「拒否」表示されるバグ駆除) |
| #160 | #158, #159 | fix: `BuildHomeDashboardService#determine_state` で「データの有無」判定を「Android UA」判定より前に移動 (= Capacitor 同期済 user にデモデータが永久表示される設計バグ駆除、+ 連携バナー残留バグも同 PR で同時 close) |
| #165 | #163 | fix: 消費 0 kcal で「バナナ余裕」誤誘導バグ駆除 (= ZERO_THRESHOLD ガード節 + Result Struct に body field 追加 + view で items.any? 分岐、design-reviewer **事前相談**で文言 / UX 確定後に実装) |
| #167 | #131 | fix: /privacy に Android Health Connect 経由の取得情報を明記 (= Google Health Connect Privacy Policy 要件遵守、案 A の 1 行追加 + 注記文言を「生データ」→「1 日合計値」に書き直し + 単位表記統一) |
| #169 | #128, #150 | polish: Capacitor splash 背景を sketchy paper 色 (#fbf8f1) に + ic_launcher 背景も同色化 (= AndroidX SplashScreen API で「白い矩形が paper 上に浮く」問題解消、design-reviewer 指摘) |
| #171 | #49 | polish: navbar 高さ 74px → 約 64px に slim 化 (= padding 14px → 8px 縮小、ボタン高 46px は維持して WCAG 2.5.5 タップ領域確保 + Issue #47 ゴール両立、design-reviewer 事前相談で候補 3 採用、flash toast 位置 top-24 → top-20 追従) |
| #173 | – | polish: navbar sticky 化 (= position: sticky + top: 0 + z-index: 30、スクロール時も常時上部表示でブランド訴求 + ナビ可用性向上、design-reviewer #171 提案、3 者全員 Approve) |
| #180 | #90 | polish: Settings ポリシーリンクを退会セクション後 (= フッター的) に移動 + 「退会前に規約を確認したい場合はこちら」補足、コメントに「インフォームドコンセント色 vs フッター UX 色」設計トレードオフ明示 |
| #182 | #83 | polish: Webhook 422 エラー文言を I18n 化 + カジュアル層向け日本語化 (= `config/locales/ja.yml` 新規 8 errors キー / 3 fields キー、生例外 message は `Rails.logger.warn` に分離して本人画面非露出、`unauthorized` 値のみ運用ログ用として英語維持、design-reviewer must-fix 反映 + 推奨コピー 4 件全採用) |
| #185 | #162, #184 | polish: banner_android UX ループ解消 + Settings に Web Android user 向け案内追加 (= **案 E** で 2 Issue 1 PR、`PlatformDetectorService.web_android?` 新設で Capacitor 排除 UA 判定、Settings 新セクションは既存 native-health セクションとサーバ UA で排他制御、文言は「アプリ取得後の本来体験 + 取得手段準備中 + 暫定 sample」3 段構成 — ユーザー局長との認識合わせで「Web 主戦場 / Capacitor は API 送信補助 / 配布 = sideload」の前提整理が大きな成果) |
| #187 | #174 (A+B+D) | polish: navbar X グループ — scroll shadow + 高さ CSS 変数化 + 未ログイン CTA (= 4 サブのうち軽量 3 件を 1 PR、`navbar_scroll_controller.js` で scrollY > 4 で `.is-scrolled` class 付与 + rAF throttle、`--navbar-height: 64px` 変数化で flash toast を `top-[calc(var(--navbar-height)+16px)]` 連動、未ログイン navbar に「ログイン」CTA、transition は `.sketch-navbar` 本体側で両方向 .15s ease — C ハンバーガーは ViewComponents 導入 #56 と並行で v1.x 持ち越し撤退、Day 8 navbar 系 4 連投回避) |
| #189 | – | polish: 公開前最終 4 件集約 (= design-reviewer 公開前 Web 最終チェック反映、Settings 見出し「Apple Shortcuts 連携」→「データ連携の設定」中立化 + リード文で iPhone/Android 両 OS 明示 / viewport-fit=cover meta 追加 / ホーム法務リンク色 var(--muted) → var(--ink-2) 濃色化で信頼感向上 / banner_android 文言「ログイン不要で見てみてください」追加で Android 評価者の早期離脱回避 — code 指摘 safe-area-inset 補正は v1.1 別 Issue #190 で起票) |
| #192 | – | feat: OGP / meta description 最小整備 (= title「weight_dialy」→「weight daily. — 日常のちいさな歩きを自動で拾う」、meta description / OGP 6 タグ / Twitter Card 4 タグ追加、og:image は既存 /icon.png 流用 + summary card 暫定、`og:url` は `request.original_url` 動的生成、専用 1200x630 画像準備でき次第 summary_large_image 格上げ予定 — SNS 共有時のプレビュー対応で公開後の長期 ROI 向上) |
| #194 | – | polish: 動線リハ反映 — banner_empty を settings_path 化 + about ページ法務リンク濃色化 (= AI コードベース動線リハで対称性/一貫性の漏れ 2 件発見。α: banner_empty.html.erb 「/settings」ハードコードを settings_path に + 陳腐化コメント削除 (banner_android #185 と対称性回復)、β: about/show.html.erb 法務リンク色 var(--muted) → var(--ink-2) (ホーム index #189 と一貫性回復)) |
| #196 | – | feat: OGP リッチ画像移行 — Claude Design 由来 1200x630 PNG (= ユーザー局長が claude.ai/design で作成した sketchy トーン HTML プロトタイプを bundle 受領、puppeteer 経由で headless Chrome レンダリング → 2400x1260 retina PNG 自動生成、`bin/render_ogp.sh` で再生成可能、フォントは Caveat/Kalam/Patrick Hand 英字 + Klee One 日本語 + Noto Color Emoji 絵文字の 3 段フォールバック、application.html.erb で og:image を /ogp.png に差し替え + twitter:card を summary_large_image 格上げ — Claude Design HTML プロトタイプ → 静的 PNG レンダリング 教材性◎) |
| #198 | – | feat: Favicon リッチ移行 — Claude Design 由来「+kc」スタンプ風 5 サイズ (= 16/32/64/180/512px、Caveat font 「+kc」+ 黄色蛍光ペン帯 + オレンジストリークドット、16px はミニ版「+」のみで縮小視認性確保。bin/render_favicon.sh で puppeteer + element.screenshot による各サイズ個別 capture、deviceScaleFactor: 1 で純粋ピクセル。link rel に sizes 属性で各ブラウザに適切な解像度指定、旧 icon.svg placeholder 削除) |
| #200 | – | polish: ログイン CTA を banner_guest に集約 (= 案 A、navbar 未ログイン CTA を削除して認知負荷回避)。動線リハで「navbar『ログイン』+ banner『Google でログイン』2 箇所同時表示」の違和感を確認、PR #187 で追加した navbar 未ログイン CTA をユーザー局長判断で逆転削除。banner_guest が「サンプル → Google でログイン」のホーム第一印象を主役、navbar はブランド訴求 (= sketchy swoosh タイトル) に集中。spec も「navbar 単体に CTA 無し」を担保する形に書き換え |
| #202 | – | polish: モバイル比率修正 + Web 下切れ予防 4 件集約 (= モバイル実機リハで判明 3 件 + 再現性なし下切れ予防 1 件)。A: bottom-grid を repeat(N, minmax(0, 1fr)) で grid item の min-width auto bleed を抑制 (= 「+5.4」「7,200」が container 右切れする事象解消)。B: banner をモバイル幅 (760px 以下) で flex-direction: column 縦並び化 (= flex-shrink: 0 ボタンが幅を奪い「これ/サン/プル/デー/タ/で/す」と 1-3 文字ずつ折り返しする事象解消)。C-2: html, body min-height: 100vh 追加 (= viewport 短コンテンツ予防策)。C-3: dashboard padding-bottom 32 → 48px (= scroll restoration / font swap layout shift 予防策)。教材性: CSS Grid の min-width auto 落とし穴 + Flexbox + flex-shrink:0 のモバイル潰れ パターンの定石対処を後輩教材としてコメント残置 |
| #204 | – | polish: AI カード flex 構造修正 + navbar モバイルボタン縮小 (画像 5 / 6 ユーザー報告由来)。AI カード: ヘッダ (= アバター + h3) だけ flex 横並び、本文以下 (= リスト / Powered by Claude / ボタン) を flex の外に出して左端揃え、アバター幅 36px + gap 10px 分の右ズレ解消。navbar mobile: モバイル幅で .sketch-navbar-name 非表示 + .sketch-btn の padding 6px 10px / font-size 14px 縮小、「設/定」「ロ/グ/ア/ウ/ト」と縦書き状の極小圧縮を解消。教材性: flex 横並びカード内 content shift の典型対処 + 「タイトル + 名前 + 複数ボタン」総幅オーバー時の定石 (= 情報密度低い要素を非表示 + ボタン縮小) |
| #206 | – | polish: 0 歩警告強化 + navbar モバイル左寄せ + ボタン padding 戻し。0 歩警告: native_health_controller.js の formatSummary で step_count === 0 時に「⚠️ Health Connect から本日のデータが取得できません + データソース設定確認」を明示誘導 (= ユーザー局長 16:11 報告「同期成功 → 実は 0 歩」事例由来、本番 DB 調査で WebhookDelivery 6 件全部 0 値と確定)。navbar mobile: PR #204 の縮小 (= padding 6px 10px) でも縦書き状圧縮が解消されず (画像 8 由来)、justify-content を space-between → flex-start に変更してボタン群を左寄せにし、padding を 8px 14px に戻して読みやすさ優先。教材性: 「API 200 + accepted_count 1」でも中身 0 値ならユーザー体験的に失敗、意味のある成功表示を区別する重要性 |
| #208 | – | docs: README に「12. Android アプリ版利用ガイド (Capacitor + Health Connect 連携)」セクション追加 (= 102 行)。子 7 #126 (APK sideload 配布手順整備) で配布開始時に参照される雛形。全体像 (データの流れ) / 前提条件 / セットアップ手順 (Step 1: 歩数計測アプリ連携 ←最重要 / Step 2: APK / Step 3: weight daily 内 OAuth + 同期) / トラブルシューティング 4 症状 (0 歩のまま / 権限不足 / Health Connect 利用不可 / エミュレータ動作確認) / 教材性メモ (読み取り/書き込み API 分離 / 「API 200 = 成功」の罠 / Capacitor plugin 落とし穴 / エミュ vs 実機差) を集約。ユーザー局長判断「E (Settings ガイダンス) は 19:00 以降緊急タスク、今は B (README) で教材性整備」を反映 |
| #210 | – | polish: .sketch-btn に white-space: nowrap + flex-shrink: 0 追加 (= 画像 10 由来「設/定」「ログ/アウト」縦書き状 2 行折り返し解消)。原因 2 つ: ① white-space デフォルト = ボタン狭幅でテキスト自動折り返し / ② flex-shrink デフォルト 1 = .sketch-navbar-right 内でボタン圧縮されて padding すら奪われる極小化。両対処を 1 行ずつ追加。教材性: flex item は default で flex-shrink: 1 で縮められる、ボタンのように内容を保ちたい要素には flex-shrink: 0 を明示するのが定石 |
| #212 | – | polish: モバイル navbar ボタン群を 6px 下にずらす微調整 (= 画像 11 由来、視覚バランス改善)。タイトル「weight daily.」が Caveat 32px で 2 行折り返し時、ボタン群が上寄り過ぎてバランス悪い → モバイル幅で `.sketch-navbar-right` に `margin-top: 6px` 追加で daily. の下半分付近に揃える。微調整レベル、副作用なし |
| #214 | – | feat: 初回アクセス welcome モーダル追加 (= iPhone Shortcuts 案内 + Android 近日公開予定 + sample 体験可)。ホーム未ログイン時の初回アクセスで表示、localStorage で「見た」フラグ保存して 2 回目以降非表示。内容: 概要 / 📱 iPhone (Apple Shortcuts 連携 3 step) / 🤖 Android (アプリ版近日公開、サンプルデータ体験可、ログイン不要)。背景クリック / Escape / 「確認しました」ボタンで閉じる + ARIA dialog 属性。未ログイン時のみ描画 (= ログイン済 user は既に使い方理解 + home_spec assertion 整合)。新規ファイル 2 つ (welcome_modal_controller.js / _welcome_modal.html.erb) |

### close した Issue (= 8 件)
- **#125 子 6 (= Capacitor 実機 E2E)** — 本日完走、Issue #40 B スコープのほぼ全達成
- **#158** (= Capacitor アプリで実データが反映されない) — PR #160 で close
- **#159** (= 連携済なのに設定画面導線が残る) — PR #160 で close (= #158 と同根の bug を 1 PR で同時駆除)
- **#163** (= 消費 0 kcal でバナナ余裕誤誘導、3 ステップ思想と矛盾) — PR #165 で close
- **#131** (= /privacy に Health Connect 取得情報明記、発表会前必須) — PR #167 で close
- **#150** (= deep link「ブラウザで開く」誤選択時の回復導線) — Phase 3 で前提解消、コメント付き手動 close
- **#128** (= Capacitor splash 背景色を sketchy paper に) — PR #169 で close
- **#49** (= navbar 高さ膨張、UI 最終段階 polish) — PR #171 で close、design-reviewer 事前相談 → 候補 3 で「タップ領域犠牲なし + 見た目改善」両立解
- **#90** (= Settings ポリシーリンクをフッター位置に) — PR #180 で close、設計トレードオフ (= インフォームドコンセント vs フッター UX) コメント残置で教材性確保
- **#83** (= Webhook 422 エラー文言の日本語化) — PR #182 で close、`ja.yml` 新規導入で他機能の I18n 拡張への雛形に。design 推奨 4 件全採用 + must-fix (生例外 message 露出) を `Rails.logger.warn` 分離で対応、教材性ポイントは「全部翻訳するのが正解ではない / ユーザー向け文言と運用ログ向け文言を分ける」
- **#162** (= banner_android 文言と CTA を Android user 向けに最適化) — PR #185 で close、案 E 内の片半分。「Android アプリ版」表記 → 「Android スマホから〜送信」(= 主アプリ感解消、Apple Shortcuts と並列の送信補助感) + sketch-btn-primary 化 + settings_path 化
- **#184** (= Settings 画面に Web 版 Android user 向け Health Connect セクション追加、本日起票 + 本日 close) — PR #185 で close、案 E 内のもう片半分。banner_android CTA の UX ループ (= 飛び先で Android 関連手がかりが何も無い) を構造解消するための新セクション追加

### 起票した Issue (= v1.1 backlog 集約 7 件)

#### 単発起票
- **#161**: refactor: 状態名 `:iphone_with_data` → `:user_with_data` リネーム
- **#162**: polish: banner_android 文言と CTA を Android user 向けに最適化

#### Day 8 終盤に集約起票 (= テーマで grouping、元の 11 個別候補を 5 Issue に整理)
- **#174**: v1.1: navbar polish set (= scroll shadow / CSS 変数化 / hamburger / login CTA、4 提案集約)
- **#175**: v1.1: Phase 3 cleanup set (= assetlinks.json 物理削除 + Mobile Chrome bypass 整理)
- **#176**: v1.1: OneTimeLoginToken 運用整備 (= GC ジョブ + Cache-Control: no-store)
- **#177**: v1.1: calorie_advice 改善 set (= ZERO_THRESHOLD 管理画面化 + AI サニティ + 同期導線)
- **#178**: v1.1: /privacy マトリクス化 + 用途別記述 (= Google Play 申請時用)

---

## 🧠 教訓ハイライト (= 4 件本日確立)

### 学び 21: AssetLinks の実機挙動は端末ガチャ、custom URL scheme 一本が最も安定

Day 7 学び 20 では「AssetLinks は Custom Tabs 内 callback 不対象」と確定したが、本日 Phase 3 実装後の実機検証 (Torque G6 / Android API 35) で **AssetLinks intent-filter が Custom Tabs 内 OAuth callback URL を横取りして発動** した。具体的には Custom Tabs が `https://weight-dialy.../auth/google_oauth2/callback` に navigate しようとした瞬間、`autoVerify=true` の intent-filter が OS レベルで横取りし、Capacitor アプリに deep link → Rails の `sessions#create` (= Phase 3 ブリッジ核心) に到達せず WebView 側で処理しようとして state 不整合で失敗。

**端末 / Android バージョン / AssetLinks verify 完了タイミング等の差で「動いたり動かなかったり」する**。つまり「AssetLinks は動かないからフォールバック実装」も「AssetLinks 前提の seamless 設計」も両方ガチャ。設計依存先として不確実すぎる。

→ **解決策**: AssetLinks intent-filter を完全削除、custom URL scheme (= `com.weightdialy.app://`) 一本で完結する設計にする。custom scheme は Android の intent-filter 仕様上、ハンドラアプリが 1 つあれば必ず発動する (= http(s) ベースの App Links と違って verify 不要、システムが scheme で routing する)。

How to apply:
- ハイブリッドアプリで OAuth する場合、AssetLinks (Universal Links / App Links) を deep link 経路として使うのは避ける
- custom URL scheme + one-time token (= server side で発行、TTL 30s + 1 回限り消費) を使うのが業界標準で安定 (= Auth0 / Firebase / Cognito モバイル SDK が全部この形)
- Android Manifest で `<data android:scheme="@string/custom_url_scheme" />` の intent-filter 一本だけで済む

### 学び 22: 外部 SDK 連携の「実装完了」判定は「permission UI が出る」までではなく「データが画面に出る」まで保留する

子 6 完走後の実機検証で、Day 7 実装に **2 つの API 仕様ミスマッチ** (= flightsClimbed typo / `granted` プロパティ存在しない) が連鎖発覚 (PR #156, #157)。両方とも **permission リクエスト UI が出る** ところまでで「子 3 完成」と判定していたため、**permission 通過後の判定 (= checkAuthorization 戻り値の shape) と queryAggregated の戻り値整合性** まで実機で踏んでいなかったことが原因。

→ 解決: 「permission リクエスト UI が出る」「APIをcallできる」までではなく、「**データが画面に意図通り表示される**」まで実装完了判定を保留する運用ルール化。

How to apply:
- 外部 SDK (= Capacitor plugin / OAuth provider / API gem) は **TypeScript 型定義 / interface 定義を必ず読む**。SDK ラッパーは内部仕様と公開 API で命名が異なることが多い (= 例: Health Connect の `FloorsClimbedRecord` は @capgo/capacitor-health の API 上 `flightsClimbed`)
- E2E (= UI トリガー → SDK 呼び出し → 戻り値判定 → 画面反映) を 1 本繋ぐまで「実装中」扱い
- 特に「権限系」「認証系」は UI が出ても通過判定が間違っていたら本番で詰む

### 学び 23: state machine の判定順は「データの有無」を最優先にする、platform / UA は同点判定でしか使わない

`BuildHomeDashboardService#determine_state` で 旧設計が `return :android if platform == :android` を `return :iphone_with_data if user.step_records.exists?` より先に書いていたため、Capacitor 同期済 user に **永久にデモデータ** が表示される設計バグ (Issue #158, #159) が発覚。

旧設計時 (= Day 5-7) は「Android UA = まだ Capacitor 連携してない user」という暗黙の前提があったが、Capacitor アプリ完成後 (= Day 8 子 6 完走) にこの前提が崩れた。

→ 解決: `determine_state` で「step_records.exists?」判定を「platform 判定」より前に移動 (PR #160、1 行差し替え)。

How to apply:
- state machine の判定では **「データ / 状態の有無」を「環境 / platform」より優先**する。「UA = ユーザータイプ」のような暗黙前提は時間経過で必ず崩れる
- `return :STATE if platform == :X` のような guard には本来 `&& !user.has_data?` が併記されるべき
- 設計時の前提は「コメントで明記 + 前提が変わった時の影響テスト spec」をセットで残しておく

### 学び 24: 「実装前のデザイン相談」で polish 往復を削減できる (= 事前 3 者レビューの拡張版)

Issue #163 (= 消費 0 kcal でバナナ余裕誤誘導) の修正で、**コードを書く前に design-reviewer に相談** (= ヘッダ文言 / 本文 / ボタン挙動 / しきい値 / AI 取扱の 5 項目) → 方針確定 → 実装 → 3 者最終レビューでほぼ無修正マージ、という流れで時間を節約できた。

旧フロー (= 実装 → 3 者レビュー → polish 反映 → 再レビュー or 妥協マージ) では、特に「コピー」「文言」系で「もう書いたから後戻り面倒」が発生し、design-reviewer の指摘が v1.1 送りになりがちだった。**事前相談で「これで進めてください」のトーンが揃えば、その後の 3 者最終レビューは確認だけで済む**。

→ 解決策: 「文言 / 状態出し分け / UX フロー」を含む実装は **着手前に design-reviewer に方針相談** を打つ運用ルール化。Day 7 学び (= 「事前 3 者レビュー」) の design-only バリエーション。

How to apply:
- 「ボタン文言」「エラーメッセージ」「空ステート文言」「状態遷移後の表示」など、コピー / UX が伴う実装は事前に design-reviewer 起票
- 質問の粒度: 「(A) ボタン非表示 / (B) ボタン残し disabled / (C) ボタン文言変更」のような選択肢を 2-3 提示すると design-reviewer が判断しやすい
- 結果として最終レビューの「文言ちゃぶ台返し」がほぼゼロになる
- 注意: 設計判断 (= モデル構造 / API 形状) は code-reviewer / strategic-reviewer の領分、混ぜない

---

## 🔥 つまずき / 学び (= 本日 10 件)

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

### 7. Health Connect の API 名 typo (= `floorsClimbed` vs `flightsClimbed`、PR #156)

子 6 完走後、設定画面の「Android Health Connect 連携」カードに **「❌ 確認エラー: Unsupported data type: FloorsClimbed」** エラー。@capgo/capacitor-health の `HealthDataType` 型は **`flightsClimbed`** (= 米国流「階段の段数」) で、Day 7 実装で `floorsClimbed` (= フロア数) と書いていた typo。plugin 内部 native レイヤは Health Connect の `FloorsClimbedRecord` (= 内部記録名は floors) を使うが、JS API 名は flights という命名ミスマッチが原因。

→ 解決: PR #156 で 3 箇所文字列置換 + UI 文言「階段(未対応)」→「階段なし」に同梱変更。`grep -r "floorsClimbed"` で 0 件確認 (= memory feedback_grep_zero_after_fix.md ルール準拠)。

How to apply:
- API ラッパー plugin の **TypeScript 型定義 / interface 定義を必ず読む**。「内部仕様書」ではなく「公開 API」が正
- typo 系 fix は 1 行修正でも grep zero 確認を Test plan に明記する

### 8. Health Connect authorization 結果の API 仕様ミスマッチ (= `result?.granted` 存在しない、PR #157)

PR #156 マージ後の実機検証で「ヘルスケアアプリで権限許可した直後に、戻ってきたアプリで『⚠️ 権限が拒否されました』」エラー。Logcat から原因即特定:

```
Health.checkAuthorization 返り値: {"readAuthorized":["steps","distance","flightsClimbed"],"readDenied":[],...}
```

つまり Health Connect は **3 つとも許可済を返している** のに、JS が `result?.granted` という **存在しないプロパティ** を見ていて常に「拒否」判定 → ボタンが「権限を許可する」のままで先に進めない。@capgo/capacitor-health の `AuthorizationStatus` 型は `{ readAuthorized, readDenied }` で `granted` 自体が存在しなかった (= Day 7 実装の API 仕様 typo)。

→ 解決: PR #157 で `allReadAuthorized(result)` ヘルパー追加、`HEALTH_READ_TYPES` が全て `readAuthorized` に含まれるかで判定。design-reviewer 指摘で「権限が拒否されました」を「Health Connect の権限が不足しています。Health Connect アプリで…」に文言変更も同梱。

How to apply:
- **学び 22 の事例 1**: permission UI が出るところまでで完了判定すると本番で詰む
- 「権限系」「認証系」エラーは Logcat の API 戻り値 raw を見ると原因が一発判明する
- 文言は「全拒否」「一部拒否」両方ありうるため断定形「拒否されました」を避けて「不足しています」表現に

### 10. 消費 0 kcal で「バナナ余裕」誤誘導 (= ratio = 0 ガード不在、PR #165、Issue #163)

Capacitor 同期完了 + state 判定 fix 後の実機確認で、**消費 0 kcal の画面に「バナナ 1 本 余裕」「ヨーグルト 1 個 余裕」** が表示されるバグ発覚。3 ステップ思想 ① (= 罪悪感を減らす) と真逆の誤誘導。

原因: `build_items` で `ratio = food_kcal / total_kcal` を計算するが、`total_kcal = 0` の時 `ratio = 0` で **常に `< 0.5` が true** → 全食品に「余裕」label。Static / AI 両方が同じ判定ルールで動くため両方バグ。

→ 解決: PR #165 で `ZERO_THRESHOLD = 30` ガード節追加 (= AI / Static を呼ばずに空ステート即返し)、`Result` Struct に `body` field 追加、view で `items.any?` 分岐。design-reviewer 事前相談で文言 / UX 確定 (= 学び 24)。

How to apply:
- **学び 23 の事例 2 (= 0 / nil ガード)**: 「ratio = 食品 / 消費」のような割り算は `divisor == 0` ケースを必ず先回りガード
- 「ゼロ除算防御 (= 技術) + UX しきい値」の **二軸を 1 つの定数で表現** する場合はコメントで両方明記 (= 後で別の場所に育つ可能性あり)

### 9. Capacitor 同期済 user にデモデータが永久表示される設計バグ (= state machine 順序、PR #160)

PR #157 で permission flow が動くようになり、ユーザーが Capacitor アプリで Health Connect 同期成功 → ホーム画面で **「+294 kcal」「サンプルデータです」表記** + **連携誘導バナー残留** という症状を目視確認。当初「実データ反映されていない」「キャッシュ問題」と仮説立てたが、コード解析で **「+294 kcal」が DemoDataService の今日値と完全一致** (= `7200 * 0.04 + 12 * 0.5 = 294`) と判明 → デモデータ強制表示の設計バグ確定。

`BuildHomeDashboardService#determine_state` で `return :android if platform == :android` を `return :iphone_with_data if user.step_records.exists?` より先に書いていたため、Capacitor アプリ (= overrideUserAgent に Android 含む) では **データの有無を見ずに `:android` 状態強制** → DemoData 返却。

→ 解決: PR #160 で 1 行順序変更 (= step_records 判定を platform 判定より前に)。Issue #158 (デモ表記) + Issue #159 (設定導線残) を 1 PR で同時 close。spec 4 件追加で回帰防止。

How to apply:
- **学び 23 の事例 1**: state machine の判定順は「データの有無」を最優先に
- 「数値が想定外」 系のバグは **既知データ (= demo / fixture / seed)** との突合チェックで原因が一発判明 (= 今回は「+294 kcal が demo の今日値と完全一致」で確定)

---

## 🤝 ユーザー (= 本人) の判断ハイライト

1. **「1 からで大丈夫」** (Phase 3 着手判断、迷いなく)
2. **「OK」「c で行きましょう」「OK ですがログインはしきれてなくて大丈夫ですか?」** (= 各段階で確認しつつ前進する慎重さ + 設計理解の深さ)
3. **「ハイブリッドで行きましょう」** (= ngrok hybrid smoke test 採用、コスト効率の判断力)
4. **「マージもしちゃってください」** (= CI 通過後の即マージ判断、authorization の明示)
5. **「過去のいきさつって見れます?」** (= セッション中の整理確認、メタ的に俯瞰)
6. **「一歩ずつ進んでる感じがしていいですね」** (= 障害連発でも前進感を維持するメンタル管理力)
7. **「ログインできました!」** (= 完走確認、達成宣言)
8. **「c は抜いて d と e やりましょう」** (= 発表会フォーム提出は本人作業として保留、記録優先)
9. **「無事に連携できました」** (= permission flow fix 後の完走確認、達成宣言 2)
10. **「a + c ハイブリッドがいいですね」「デザイン担当にも今の段階で意見を聞いてみましょう」** (= 実装前の事前 design 相談、3 者並列レビューを「事後」だけでなく「事前」にも回す判断)
11. **「鮮度優先で a にしましょう」** (= dev-log ルール違反を即指摘 → 同 session 内 retroactive 反映、運用ルールの厳守姿勢)
12. **「render cli とか render の MCP とか入れてみませんか?」** (= 開発インフラ投資の提案、「待ち時間」を tooling 改善に回す思考)

---

## 📊 統計

- マージした PR: **27 本** (= 上記 + #214 初回 welcome モーダル)
- close した Issue: **13 件** (= 12 件 + #106 既対応確認による close) + Issue #174 部分 close (= A+B+D 完了、C のみ v1.1 持ち越し)
- 起票した Issue (= v1.1 backlog): **9 件** (= 当日内 #190 safe-area-inset 補正起票追加)
- 全体 spec: 431 → **557 examples** (= +126)
- 教訓: **4 件** (= 学び 21-24)
- つまずき / 学び: **10 件**
- セッション時間: **約 9 時間** (= 朝 06:00〜15:00 過ぎ、発表会まで残り ~4h)

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
