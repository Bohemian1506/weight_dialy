# Android アプリ版利用ガイド (Capacitor + Health Connect 連携)

> 元は README.md の 12 章だったが、Health Connect 周辺の前提条件・トラブルシューティング・教材性メモが揃って約 130 行になったため `docs/android-install.md` に分離 (= deploy-render.md と同じ方針、必要な人だけ参照する技術詳細書)。

> **配布状況**: v1.0 = `v0.1.0` 以降の APK を [GitHub Releases (最新)](https://github.com/Bohemian1506/weight_dialy/releases/latest) から sideload 配布中 (= Issue #126 完走、2026-05-12 開始)。**debug 署名** + dogfood 用途のため、初回インストール時は Play Protect の「未確認のアプリ」警告 + 提供元を許可するダイアログが出ます (= 詳細は [§3 Step 2](#step-2-weight-daily-アプリのインストール))。

## 1. 全体像 (= データの流れ)

```
スマホの歩数計測アプリ (Google Fit 等) → Health Connect (= Android の OS レベル健康データハブ) → weight daily Android アプリ (= Capacitor + @capgo/capacitor-health) → Webhook POST → Rails サーバ → ダッシュボード表示
```

**ポイント**: Health Connect は **データの読み取り API と書き込み API が完全に分離** されている。weight daily アプリは「読み取り」専用で歩数を取得するが、その前に **書き込みアプリ** (= Google Fit / Samsung Health 等) が Health Connect にデータを書き込んでくれている必要がある。この Android 仕様を踏まえないと「同期成功表示 → 実は 0 歩」のミスリードに陥る (= Day 8 ユーザー局長報告事例、PR #206 で警告誘導追加)。

## 2. 前提条件 (= ユーザー環境側)

1. **Android 9+ (= API 28+)**: @capgo/capacitor-health の対応下限
2. **Health Connect アプリのインストール**:
   - Android 14+: OS にプリインストール (= 設定 → アプリ → Health Connect で確認可)
   - Android 9-13: Google Play から手動インストール (= 「Health Connect by Android」)
3. **歩数計測アプリ (= Health Connect 書き込みアプリ)** のインストール + 設定:
   - **Google Fit** (推奨、ほぼ全 Android 対応): Google Play から無料インストール
   - **Samsung Health** (Galaxy 端末標準): プリインストール、Health Connect と公式統合
   - **Fitbit** / **Garmin Connect** (= 専用デバイス + アプリ): デバイスとセット
   - ⚠️ **「デイリーステップ」など Health Connect 非対応アプリ**は不可。Health Connect → 「データとアクセス」に該当アプリが表示されない場合は対応外なので別アプリへ切替

## 3. セットアップ手順 (= 順序重要)

### Step 1: 歩数計測アプリの Health Connect 連携を有効化

例: Google Fit 経由

1. Google Play で **Google Fit** をインストール
2. Google Fit を起動 → Google アカウントでログイン
3. アクティビティ計測がオンになっていることを確認 (= 通常デフォルト ON)
4. **Health Connect アプリ** を開く → **データとアクセス** → **Google Fit** が表示されていることを確認 (= 表示されない場合は Google Fit を一度起動して権限ダイアログを承認)
5. Google Fit に **「歩数」「距離」「上った階数」の書き込み許可** を付与
6. 数分待つ (= Google Fit が過去データを Health Connect に書き込む)
7. **Health Connect の「歩数」**を見て、本日の歩数が反映されていることを確認

### Step 2: weight daily アプリのインストール

1. [GitHub Releases (最新)](https://github.com/Bohemian1506/weight_dialy/releases/latest) を Android 端末のブラウザで開き、Assets 内の `weight-dialy-v*-debug.apk` をタップしてダウンロード (= PC で DL → USB / Google Drive 経由でも可)
2. APK をタップしてインストール → **「このアプリのインストールを許可しますか」 ダイアログ** が出たら「設定」 → **「この提供元を許可」 をオン** (= Android 8 以降の大半の機種、ダウンロードに使ったブラウザに対して許可)
   - ダイアログが出ない場合: Android 設定 → セキュリティ → **「不明なアプリのインストール」** または **「不明なソース」** → ダウンロードに使ったブラウザを許可 (= 機種により「特別なアプリアクセス」配下、表記は Android バージョン依存)
3. インストール画面に戻る → Play Protect の **「未確認のアプリ」 警告** は **「許可」** をタップ (= debug 署名のため警告は正常、悪意のあるアプリではない)

### Step 3: weight daily アプリで Google ログイン + Health Connect 連携

1. アプリ起動 → ホーム画面の「Google でログイン」をタップ → Custom Tabs で OAuth 完走
2. Settings 画面の **「📱 Android Health Connect 連携」** セクションが表示される (= Capacitor 検知時のみ)
3. **「権限を許可する」** をタップ → Health Connect の権限ダイアログが出るので、**「歩数」「距離」「上った階数」の読み取り**を許可
4. 自動で「同期する」ボタンが表示される
5. **「同期する」** をタップ → 「✅ 今日のデータを取得しました — N 歩 / X.X km / N 階」と表示されればサーバー送信成功
6. ホーム画面に戻ると、自分の実データがダッシュボードに反映されている

## 4. トラブルシューティング (= 教材性メイン)

### 症状 A: 「✅ 送信完了 1 件保存」と表示されるが、ホーム画面で 0 歩のまま

**原因**: Health Connect 自体に本日の歩数データが届いていない (= 書き込みアプリが連携していない or データ流入していない)。weight daily アプリは正常動作しており、サーバー側にも 0 値のレコードが保存されている (= status: "success", accepted_count: 1, payload.records[0].steps: 0)。

**確認手順**:
1. Health Connect アプリを開いて本日の歩数を確認 → 0 歩ならこの仮説が確定
2. 歩数計測アプリ (= Google Fit 等) が起動している + Health Connect 連携が ON か確認
3. Health Connect → データとアクセス → 該当アプリの書き込み許可がオンか確認
4. それでも 0 歩なら、別の歩数計測アプリ (= Samsung Health, Mi Fit 等) を試す

**コード側の警告**: `app/javascript/controllers/native_health_controller.js` の `formatSummary` で `step_count === 0` 時に明示的に警告メッセージを出すよう実装済 (= PR #206)。

### 症状 B: 「⚠️ Health Connect の権限が不足しています」表示

**原因**: 「権限を許可する」タップ時、Health Connect の権限ダイアログで一部 (= 歩数 / 距離 / 階段) を拒否している。

**対応**: Health Connect アプリ → データとアクセス → weight daily → 全ての読み取り許可をオン。

**設計上の注意**: 「全部拒否」と「一部だけ拒否」の両方ありうるため、weight daily 側のメッセージは断定形「拒否されました」を避けて「不足しています」表現に統一済 (= PR #157 design レビュー反映)。

### 症状 C: 「⚠️ Health Connect 利用不可」表示

**原因**:
- Android バージョンが 9 未満 (= 動作対象外)
- Health Connect アプリが未インストール (= Android 9-13 で Google Play からのインストールを忘れている)
- 端末メーカーが Health Connect をブロック (= 一部の Chinese OEM)

**対応**: Health Connect の inAvailable() API がエラー reason を返してくるので、`app/javascript/controllers/native_health_controller.js` の `checkPermission` でログ確認 → 該当原因に応じてユーザーに案内。

### 症状 D: エミュレータ (= AVD) で歩数 0 のまま

**原因**: AVD には**物理歩数センサーが無い** = 自動では Health Connect にデータが書き込まれない。

**対応**:
- 開発検証目的なら、`adb shell` から Health Connect に**テストデータをインジェクト** (= Health Connect Toolbox 経由)
- または、エミュレータでの完全動作確認は諦めて **物理スマホでの検証** に切り替える (= 推奨)
- 配布版では本番想定で物理スマホ動作を担保

## 5. 教材性メモ (= 後輩への伝言)

- **Health Connect は「読み取り API ⇄ 書き込み API」で別の仕組み**: weight daily が読み取り専用なら、書き込み側 (= Google Fit 等) を含めた **エコシステム全体** をユーザーに案内する必要がある
- **API 200 + accepted_count 1 = ユーザー体験的に「成功」とは限らない**: 中身が 0 値ならユーザーは「同期されてない」と感じる。**意味のある成功** (= 数値 > 0) と「処理通過」を区別して UI 表示する重要性 (= PR #206)
- **Capacitor + Health Connect の plugin 落とし穴**: @capgo/capacitor-health の API 命名が Health Connect 内部 (= FloorsClimbedRecord) と公開 API (= flightsClimbed) で違う、`AuthorizationStatus` 型は `granted` ではなく `readAuthorized: HealthDataType[]` 形式 (= Day 7 学び 22 + PR #156, #157 由来)
- **エミュレータ vs 実機の差**: 物理センサー有無の違いで「動く / 動かない」が分かれる、外部 SDK 連携は **必ず実機でも検証** が定石 (= 学び 21 端末ガチャ含めた教訓)

## 6. なぜこのアーキテクチャか (= 業界標準の王道、Web 完結を待っても無駄)

「Web ベースのアプリなのに、なぜ Capacitor + ネイティブ SDK が必要?」 = 後輩がまず疑問に思うポイント。**結論: 業界標準を踏襲しているだけ、Web 完結のショートカットは構造的に存在しない。**

### Google の Health 系 API 二分岐 (= 2026 年時点)

| API | タイプ | 対象 | 一般 Android スマホで使えるか |
|---|---|---|---|
| Google Fit REST API | Web | 一般 Android | ❌ **2026 年中廃止確定** |
| Health Connect SDK | Android Native | 一般 Android | ✅ ただし**ネイティブ SDK 経由のみ** (= Web/REST なし) |
| Google Health API | Web | **Fitbit + Pixel Watch のみ** | ❌ 一般 Android スマホ非対応 |

### Apple HealthKit も同じ方針

WWDC 2025 で発表されたのも `Medications API` (= ネイティブ iOS) のみで、REST 公開なし。Apple Shortcuts + Webhook が回避策の最善解 (= 本アプリの iPhone 連携経路もこれ)。

### なぜ Web/REST が出ないか

「健康データを **端末上に閉じる**、クラウド経由で外部に流さない」プライバシー方針が **Apple / Google 両社で一致**。これは意図的設計で、短中期 (2026 年内) に変わる発表は**ない**ことが api-researcher 調査で確定 (= dev-log day-8 + Issue #219 参照)。

### 結果として業界標準は

**「ハイブリッドアプリ (Capacitor / React Native 等) + ネイティブ SDK + 自前 Webhook」** が唯一の現実解。weight daily の現アーキテクチャ (= Capacitor + Health Connect Native + Rails Webhook) はこの王道を踏襲している。**Web 公式 API を待つ戦略には意味がなく、ハイブリッドアプリ路線で確定でよい**。

### ニッチオプション

ターゲットが Pixel Watch / Fitbit ユーザーなら **Google Health API で Web 完結連携** が可能 (= Issue #219、v1.1 backlog)。ただし weight daily のメインターゲット (= 通勤通学カジュアル層、一般 Android スマホ) には届かない。サードパーティ aggregator (Thryve / Terra / Validic 等) は月額課金、個人プロジェクトには不向き。
