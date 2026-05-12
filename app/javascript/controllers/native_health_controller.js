import { Controller } from "@hotwired/stimulus"

// @capgo/capacitor-health (v8.4.9) の HealthDataType 定義に合わせる。
// Health Connect 内部レコードは FloorsClimbedRecord だが、plugin の JS 公開 API は米国流の "flightsClimbed" (= 階段の段数)。
// 旧コードでは "floorsClimbed" と書かれており permission チェックで "Unsupported data type" エラーになっていた (2026-05-06 実機検証で発覚)。
const HEALTH_READ_TYPES = ["steps", "distance", "flightsClimbed"]

// Issue #138 / #273: HTTP status 別の日本語フォールバック + recoveryButton 2 mode (= settings / retry)。
// 401 (= token 無効) → settings 誘導 / 5xx (= サーバー側一過性) → retry / 4xx 一般 (= 413/422) → 文言のみ (= 復帰導線が一意に決まらない)。
// 想定外 status (= 404 / 429 等) は呼び出し側で `HTTP ${status}` に fallback。
// **本 PR は 2 mode で確定 (= 3 種類目 mode は v1.2 以降の検討、必要時は `RECOVERY_ACTIONS` マップへ昇格検討)**。
const RECOVERY_LABELS = {
  settings: "設定ページでトークンを再生成 →",
  retry: "しばらく待ってからもう一度試す →"
}

// Issue #276: 5xx 連続 2 回目以降の待機誘導文言 (= retry ボタン非表示 + 「待つ」 への正しい誘導)。
// 1 回目 retry は通常の status 文言 + retry ボタン、2 回目以降は連打抑制のため本文言で確定上書き + ボタン非表示。
// 「数分後」: カジュアル層は「しばらく」 を 10 秒〜1 時間まで読み取り幅広い (= design-reviewer C-1)、目安を明示。
// 「画面を下に引っ張ると再読込」: ボタン非表示後の代替導線を文言に統合 (= design-reviewer I-1、Capacitor アプリの Pull-to-Refresh 前提)。
const RETRY_EXHAUSTED_STATUS = "❌ サーバーが応答できていません。数分後にもう一度お試しください（画面を下に引っ張ると再読込できます）"
// RETRY_THRESHOLD = 2 の根拠: 連打 1 回まで許容 (= 一過性 5xx で 1 retry は妥当)、3 回以上は server 復旧待ちが筋。
// **数値は仮置き、Day 14+ 実運用で再評価候補** (= 自己提唱の言い切り回避、memory `feedback_self_proposal_relativization.md` 集計慣習「仮置き明示」 慣行に従う)。
const RETRY_THRESHOLD = 2

// Issue #314: アプリ起動 / 復帰時の自動同期 + 同期ボタン UI 改善 (= WorkManager 代替の軽量実装)。
// localStorage に最終同期成功時刻 (ISO 8601) を保存、AUTO_SYNC_THRESHOLD_HOURS 以上経過 + permission OK + token 設定済で
// `App.addListener("appStateChange")` の前面復帰トリガーから自動同期発火。STALE_WARNING_HOURS 以上未同期で UI に ⚠️ ヒント。
// **WorkManager (= 子 5b 元案) は @capgo/capacitor-health 未対応 + Kotlin カスタム実装 2-3 日工数のため代替**
// (= memory `project_capacitor_health_workmanager_research.md` 由来)。
const LAST_SYNC_KEY = "weight_dialy_last_sync_at"
const AUTO_SYNC_THRESHOLD_HOURS = 6     // 6h 以上経過したら起動 / 復帰時に自動同期
const STALE_WARNING_HOURS = 24          // 24h 以上未同期で ⚠️ ヒント表示

// 5xx 系の文言は **ボタン文言「しばらく待ってからもう一度試す →」 と冗長になるため文末「再試行してください」 を削った** (= Issue #273 design-reviewer C-1)。
// 1 つの UI イベント (= 5xx) に「待ってから」 表現が status 文言とボタン文言で 2 回出ると視覚的にうるさい。
// status 文言は「何が起きたか」、ボタン文言は「次にやること」 の役割分担を明示。
const STATUS_MESSAGES = {
  401: "トークンが無効です。設定ページでトークンを再生成してください",
  413: "送信データが多すぎます。しばらく待ってから再試行してください",
  422: "データの形式に問題があります",
  500: "サーバー側のエラーです",
  502: "サーバーが応答しません。ネットワーク接続を確認してください",
  503: "サーバーが混み合っています"
}

export default class extends Controller {
  static targets = ["status", "requestButton", "syncButton", "recoveryButton", "lastSyncDisplay"]
  static values = { webhookToken: String }

  async connect() {
    // Issue #276: connect 時に retry カウンタを 0 リセット (= turbo navigation 跨ぎでも初期化される)。
    this.retryCount = 0
    // Issue #314: 自動同期と手動 sync の重複ガード兼、自動同期中フラグ (= sync() 内で UX 分岐に使う)。
    this.isAutoSyncing = false
    if (!this.isCapacitorNative()) {
      return
    }
    this.element.style.display = ""

    // Issue #314: アプリ前面復帰時の自動同期トリガー登録。
    // disconnect() で remove するため handle を保持。
    this.appStateListener = await this.registerAppStateListener()

    this.checkPermission().catch((error) => {
      this.showStatus(`❌ 初期化エラー: ${this.errorMessage(error)}`)
    })
    this.updateLastSyncDisplay()
  }

  // Issue #314: Stimulus disconnect ライフサイクル。turbo navigation 跨ぎや要素削除時に
  // App listener を解除しないと「同 listener が複数回登録 → state 変化で複数回発火」 のリーク発生。
  disconnect() {
    if (this.appStateListener?.remove) {
      this.appStateListener.remove().catch(() => {})
    }
    this.appStateListener = null
  }

  isCapacitorNative() {
    const cap = window.Capacitor
    return typeof cap !== "undefined" &&
      typeof cap.isNativePlatform === "function" &&
      cap.isNativePlatform()
  }

  healthPlugin() {
    return window.Capacitor?.Plugins?.Health
  }

  async checkPermission() {
    const Health = this.healthPlugin()
    if (!Health) {
      this.showStatus("⚠️ Health プラグインが見つかりません (cap sync 不足の可能性)")
      return
    }

    try {
      const availability = await Health.isAvailable()
      if (!availability?.available) {
        this.showStatus(`⚠️ Health Connect 利用不可: ${availability?.reason || "原因不明"}`)
        return
      }

      const result = await Health.checkAuthorization({ read: HEALTH_READ_TYPES })
      if (this.allReadAuthorized(result)) {
        this.requestButtonTarget.style.display = "none"
        this.syncButtonTarget.style.display = ""
        await this.refreshData()
      } else {
        this.showStatus("⏳ Health Connect の権限が必要です")
        this.requestButtonTarget.style.display = ""
        this.syncButtonTarget.style.display = "none"
      }
    } catch (error) {
      this.showStatus(`❌ 確認エラー: ${this.errorMessage(error)}`)
    }
  }

  async requestPermission() {
    const Health = this.healthPlugin()
    if (!Health) return

    try {
      const result = await Health.requestAuthorization({ read: HEALTH_READ_TYPES })
      if (this.allReadAuthorized(result)) {
        this.requestButtonTarget.style.display = "none"
        this.syncButtonTarget.style.display = ""
        await this.refreshData()
      } else {
        // 「全部拒否」と「一部だけ拒否」の両方ありうるため、断定形を避けて「不足」表現にする (= design レビュー指摘)。
        // ナビゲーションパスは Android 機種でラベル差があるので Health Connect アプリ経由の指示にする。
        this.showStatus("⚠️ Health Connect の権限が不足しています。Health Connect アプリで「歩数 / 距離 / 階段」を許可してください")
      }
    } catch (error) {
      this.showStatus(`❌ リクエストエラー: ${this.errorMessage(error)}`)
    }
  }

  // @capgo/capacitor-health (v8.4.9) の AuthorizationStatus 型は { readAuthorized: HealthDataType[], readDenied: HealthDataType[] } のみ公開。
  // 旧コードでは存在しない `result.granted` を参照しており、Health Connect が全権限許可を返しても常に未許可判定になっていた
  // (2026-05-06 実機検証で発覚、HEALTH_READ_TYPES typo fix と同じセッションで連鎖検出)。
  // 本質的な反省点: Day 7 実装時に「permission UI が出るところ」までで実装完了判定を打っていたため、
  // permission 通過後の判定 (= ここ) と queryAggregated 戻り値の整合性が温存されていた。
  // 外部 SDK 連携は「permission UI → 通過判定 → データ取得 → 整形 → サーバ送信」の 1 本繋ぎが完了するまで未完了扱いにすべき。
  // 必要 dataType (= HEALTH_READ_TYPES) が全て readAuthorized に含まれていれば許可済とみなす。
  allReadAuthorized(result) {
    const authorized = result?.readAuthorized
    if (!Array.isArray(authorized)) return false
    return HEALTH_READ_TYPES.every((type) => authorized.includes(type))
  }

  // status 表示は先頭絵文字でトーンを自動分岐 (= success / error / info)。
  // 発表会デモで成功 / 失敗の瞬間を視認しやすくするため、太字 + 色強調を適用する。
  showStatus(message) {
    this.statusTarget.textContent = message
    if (message.startsWith("✅")) {
      this.statusTarget.style.fontWeight = "700"
      this.statusTarget.style.color = "var(--ink)"
    } else if (message.startsWith("❌") || message.startsWith("⚠️")) {
      this.statusTarget.style.fontWeight = "700"
      this.statusTarget.style.color = "var(--danger)"
    } else {
      this.statusTarget.style.fontWeight = ""
      this.statusTarget.style.color = ""
    }
  }

  errorMessage(error) {
    if (!error) return "原因不明"
    return error.message || error.errorMessage || String(error)
  }

  // -------------------------------------------------------------------------
  // データ取得 (子 Issue #122 / 子 4)
  // -------------------------------------------------------------------------

  async refreshData() {
    this.showStatus("⏳ データ取得中...")
    const data = await this.fetchTodayData()
    if (!data) return
    this.lastFetchedData = data
    this.showStatus(this.formatSummary(data))
  }

  async fetchTodayData() {
    const Health = this.healthPlugin()
    if (!Health) return null

    const startDate = this.startOfTodayISO()
    const endDate = new Date().toISOString()

    try {
      // 個別フォールバック方式: 1 dataType 失敗しても他が取れれば全体は成立
      const [steps, distance, floors] = await Promise.all([
        this.queryAggregatedSafe(Health, "steps", startDate, endDate),
        this.queryAggregatedSafe(Health, "distance", startDate, endDate),
        this.queryAggregatedSafe(Health, "flightsClimbed", startDate, endDate)
      ])
      return {
        step_count: this.sumSamples(steps),
        distance_meters: this.sumSamples(distance),
        floors_climbed: this.sumSamples(floors),
        measured_on: this.todayISODate()
      }
    } catch (error) {
      this.showStatus(`❌ 取得エラー: ${this.errorMessage(error)}`)
      return null
    }
  }

  async queryAggregatedSafe(Health, dataType, startDate, endDate) {
    try {
      return await Health.queryAggregated({
        dataType, startDate, endDate,
        bucket: "day", aggregation: "sum"
      })
    } catch (error) {
      console.warn(`queryAggregated failed for ${dataType}:`, error)
      return { samples: [] }
    }
  }

  sumSamples(result) {
    if (!result?.samples?.length) return 0
    return result.samples.reduce((acc, s) => acc + (s?.value || 0), 0)
  }

  // ローカル時刻 (= 日本ユーザー想定なので JST) の 0:00 を ISO 8601 形式で返す。
  // toISOString() は UTC 化するため、setHours(0,0,0,0) と併用すると前日 15:00 UTC になり日付ズレ発生。
  // タイムゾーンオフセット付きで返すことで Health Connect の集計バケットを意図通りに切る。
  startOfTodayISO() {
    const d = new Date()
    d.setHours(0, 0, 0, 0)
    return this.toLocalISOString(d)
  }

  // ローカル日付の YYYY-MM-DD。toISOString().slice(0,10) は UTC 基準のため、JST 0-8 時台で前日扱いになる。
  // measured_on (= サーバー側 recorded_on) として送るため必ずローカル日付。
  todayISODate() {
    const d = new Date()
    const pad = (n) => String(n).padStart(2, "0")
    return `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}`
  }

  toLocalISOString(d) {
    const pad = (n) => String(n).padStart(2, "0")
    const offsetMin = -d.getTimezoneOffset()
    const sign = offsetMin >= 0 ? "+" : "-"
    const offH = pad(Math.floor(Math.abs(offsetMin) / 60))
    const offM = pad(Math.abs(offsetMin) % 60)
    return `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}T${pad(d.getHours())}:${pad(d.getMinutes())}:${pad(d.getSeconds())}${sign}${offH}:${offM}`
  }

  formatSummary(data) {
    // 0 歩は Health Connect 自体にデータが届いていない可能性が高い。
    // よくある原因: ① Health Connect で「データソース」(= 歩数計測アプリ) が未設定
    //             ② エミュレータ (= 物理歩数センサー無し)
    //             ③ 計測アプリの書き込み権限 OFF
    // ユーザー局長が「同期成功 → 実は 0 歩」のミスリードでハマった事例から、明示的に「Health Connect 側を見て」と誘導する。
    if ((data.step_count || 0) === 0) {
      return "⚠️ Health Connect から本日のデータが取得できません。Health Connect アプリで「データソース」が設定され、歩数計測アプリ (デイリーステップ / Google Fit 等) の書き込みが有効か確認してください。"
    }

    const steps = (data.step_count || 0).toLocaleString()
    const km = ((data.distance_meters || 0) / 1000).toFixed(1) // ホーム画面と同じ 1 桁表示
    const floors = data.floors_climbed
    // 階段データ (= flightsClimbed) は Health Connect に記録があれば取得できる。
    // 0 の場合は「今日まだ階段昇降がない」or「ソース device が未対応」のいずれかなので「階段なし」と表示する。
    const floorsPart = floors > 0 ? ` / ${floors} 階` : " / 階段なし"
    return `✅ 今日のデータを取得しました — ${steps} 歩 / ${km} km${floorsPart}`
  }

  // -------------------------------------------------------------------------
  // Issue #314: アプリ起動 / 復帰時の自動同期 + 同期状態 UI (= WorkManager 代替軽量実装)
  // -------------------------------------------------------------------------

  // Capacitor App プラグインの appStateChange イベントを購読。前面復帰 (= isActive=true) で
  // 自動同期判定を回す。App プラグインが未インストール / 古い場合は静かに諦める (= 既存手動同期は機能継続)。
  async registerAppStateListener() {
    const App = window.Capacitor?.Plugins?.App
    if (!App?.addListener) return null
    try {
      return await App.addListener("appStateChange", (state) => {
        if (state?.isActive) {
          this.handleAppResume().catch((error) => {
            console.warn("auto-sync resume handling failed:", error)
          })
        }
      })
    } catch (error) {
      console.warn("App listener registration failed:", error)
      return null
    }
  }

  // 前面復帰時の処理: 表示更新 + 自動同期判定。
  // 手動 sync 進行中は重複起動しない (= shouldAutoSync 内でガード)。
  async handleAppResume() {
    this.updateLastSyncDisplay()
    if (!this.shouldAutoSync()) return
    await this.autoSync()
  }

  // 自動同期の発火条件 (= AND 結合):
  // 1. 自動同期 / 手動 sync の同時進行中でない (= isAutoSyncing / syncButton.disabled)
  // 2. permission 取得済 (= syncButton 表示中 = checkAuthorization 成功の証拠)
  // 3. webhook token 設定済
  // 4. localStorage 最終同期から AUTO_SYNC_THRESHOLD_HOURS 以上経過 (or 未同期)
  // v1.2 で WorkManager 本実装 (= Kotlin Worker) を導入する場合は、本メソッド冒頭で
  // `Capacitor.isNativeAvailable("WorkManagerSync")` 相当の gating を入れて JS / Native の二重発火を防ぐ。
  // (= strategic-reviewer Should Fix、将来の自分への置き手紙)
  shouldAutoSync() {
    if (this.isAutoSyncing) return false
    // Issue #314 code-reviewer 指摘: Turbo navigation 跨ぎで target が一時的に切れている可能性に備えて has check。
    if (!this.hasSyncButtonTarget) return false
    if (this.syncButtonTarget.disabled) return false
    if (this.syncButtonTarget.style.display === "none") return false  // permission 未取得
    if (!this.webhookTokenValue) return false
    const lastSync = this.readLastSync()
    if (!lastSync) return true  // 未同期 = 即同期
    const hoursElapsed = (Date.now() - lastSync.getTime()) / 1000 / 3600
    return hoursElapsed >= AUTO_SYNC_THRESHOLD_HOURS
  }

  // 自動同期は手動 sync と同じ Webhook フローを使う (= 重複コード回避)。
  // ただし UI 表記は控えめに + home 遷移は抑制 (= 現在のページを邪魔しない、sync() 内 isAutoSyncing 分岐)。
  async autoSync() {
    this.isAutoSyncing = true
    // Issue #314 code-reviewer race window 指摘: refreshData 実行中に手動 sync ボタン押下で
    // 二重実行が起きる可能性 → autoSync 冒頭で syncButton を disabled、finally で復帰。
    // shouldAutoSync 側の `syncButton.disabled` チェックと併せ自動同期の再入を物理防止。
    if (this.hasSyncButtonTarget) {
      this.syncButtonTarget.disabled = true
    }
    try {
      this.showStatus("⏳ 自動同期中...")
      await this.refreshData()
      if (!this.lastFetchedData) return  // 取得失敗 (= 0 件 + 警告文言) は静かに諦める
      await this.sync()
    } finally {
      this.isAutoSyncing = false
      if (this.hasSyncButtonTarget) {
        this.syncButtonTarget.disabled = false
      }
    }
  }

  // localStorage から最終同期時刻を読む。破損データ (= 旧キー / 手動編集) は null として扱う。
  // private browsing / Storage API 制限環境では読み書き失敗するが、アプリは動く前提 (= try/catch で握りつぶし)。
  readLastSync() {
    try {
      const raw = localStorage.getItem(LAST_SYNC_KEY)
      if (!raw) return null
      const date = new Date(raw)
      if (isNaN(date.getTime())) return null
      return date
    } catch (_) {
      return null
    }
  }

  // localStorage 書き込み (= 同期成功時に呼ぶ)。private browsing 等で失敗してもアプリは動く前提。
  writeLastSync(date) {
    try {
      localStorage.setItem(LAST_SYNC_KEY, date.toISOString())
    } catch (error) {
      console.warn("writeLastSync failed:", error)
    }
  }

  // 「最終同期: N 時間前」 表示の更新 + STALE_WARNING_HOURS 以上で data-warning="true" → CSS で ⚠️ ヒント。
  // lastSyncDisplay target が無いレイアウト (= 旧版 partial) でも壊れないよう has check で gating。
  updateLastSyncDisplay() {
    if (!this.hasLastSyncDisplayTarget) return
    const lastSync = this.readLastSync()
    if (!lastSync) {
      // Issue #314 design-reviewer 指摘: 「未同期」 は責めるトーン (= 3 ステップ思想と齟齬)、
      // 「まだ同期されていません」 で中立 + データ未送信状態を明示。warning は出さない
      // (= ボタン押下を促す導線は既存 syncButton で十分、非対称はカジュアル層には筋良い)。
      this.lastSyncDisplayTarget.textContent = "まだ同期されていません"
      this.lastSyncDisplayTarget.dataset.warning = "false"
      return
    }
    const elapsedSec = (Date.now() - lastSync.getTime()) / 1000
    this.lastSyncDisplayTarget.textContent = `最終同期: ${this.formatRelativeTime(elapsedSec)}`
    this.lastSyncDisplayTarget.dataset.warning =
      elapsedSec / 3600 >= STALE_WARNING_HOURS ? "true" : "false"
  }

  // 秒数を「N 秒前 / N 分前 / N 時間前 / N 日前」 に整形 (= relative time)。
  // Intl.RelativeTimeFormat はカジュアル層には冗長な英語混じり表示になりがちなので自前整形。
  formatRelativeTime(elapsedSec) {
    if (elapsedSec < 10) return "たった今"  // Issue #314 code-reviewer 🟢: 0 秒ジャストの体感を救済
    if (elapsedSec < 60) return "数秒前"
    if (elapsedSec < 3600) return `${Math.floor(elapsedSec / 60)} 分前`
    if (elapsedSec < 86400) return `${Math.floor(elapsedSec / 3600)} 時間前`
    return `${Math.floor(elapsedSec / 86400)} 日前`
  }

  // -------------------------------------------------------------------------
  // Webhook POST フロー (子 Issue #123 / 子 5a = MVP)
  // -------------------------------------------------------------------------

  // sync は「子 4 で取得したデータをそのまま POST」する設計。
  // 連打しても同日 recorded_on は冪等 (= サーバー側 find_or_initialize_by で同じレコードを上書き) のため副作用なし。
  // 子 5b (WorkManager 自動化) でこのロジックを Worker 化する場合も「取得 → POST」の 1 トランザクション前提を継承する。
  async sync() {
    if (!this.lastFetchedData) {
      this.showStatus("⚠️ データ未取得です。再読込してください")
      return
    }
    // pre-flight ガード: token 未設定はセッション中断時の異常系で通常起きない (= recoveryButton は出さず文言のみで OK、Issue #138 範囲外)。
    if (!this.webhookTokenValue) {
      this.showStatus("⚠️ webhook token 未設定 (= ログインし直してください)")
      return
    }

    this.showStatus("📡 送信中...")
    this.syncButtonTarget.disabled = true
    // 直前の sync で 401 となり recoveryButton が表示されたままの場合に備えて非表示に戻す (= UX バグ防止、code-reviewer ⚠️ 由来)。
    if (this.hasRecoveryButtonTarget) {
      this.recoveryButtonTarget.style.display = "none"
    }

    try {
      const data = this.lastFetchedData
      // Webhook サーバー側のフィールド名は flights_climbed (= JS 側 floors_climbed から変換)、
      // distance_meters は整数想定なので Math.round で揃える。
      const payload = {
        records: [{
          recorded_on: data.measured_on,
          steps: data.step_count,
          distance_meters: Math.round(data.distance_meters || 0),
          flights_climbed: data.floors_climbed
        }]
      }

      const response = await fetch("/webhooks/health_data", {
        method: "POST",
        headers: {
          "Authorization": `Bearer ${this.webhookTokenValue}`,
          "Content-Type": "application/json"
        },
        body: JSON.stringify(payload)
      })

      if (!response.ok) {
        const errorBody = await response.text()
        // サーバーは {error: "..."} JSON で 4xx を返す設計、JSON parse 成功時は error を抜粋。
        // パース失敗時は生 body の先頭 80 字でフォールバック。
        let bodyMessage = errorBody.slice(0, 80)
        try { bodyMessage = JSON.parse(errorBody).error ?? bodyMessage } catch (_) {}

        const is5xx = [500, 502, 503].includes(response.status)

        // Issue #276: 5xx 連続失敗時はカウンタを上げて 2 回目以降を「待つ」 誘導に切替。
        // 4xx 系は単発で復帰導線が決まる (= 401/413/422) ためカウンタ対象外。
        if (is5xx) {
          this.retryCount++
          if (this.retryCount >= RETRY_THRESHOLD) {
            this.showStatus(RETRY_EXHAUSTED_STATUS)
            if (this.hasRecoveryButtonTarget) {
              this.recoveryButtonTarget.style.display = "none"
            }
            return
          }
        }

        // HTTP status 別の日本語フォールバック (Issue #138)。STATUS_MESSAGES にあれば優先、
        // なければ従来通り `HTTP ${status}: ${body 抜粋}` で開発者 dogfood 互換。
        const friendlyMessage = STATUS_MESSAGES[response.status]
        const display = friendlyMessage
          ? `❌ ${friendlyMessage}`
          : `❌ 送信失敗 (HTTP ${response.status}): ${bodyMessage}`
        this.showStatus(display)
        // Issue #314 code-reviewer 指摘: 自動同期失敗時は recoveryButton 表示を抑止
        // (= ユーザーが別画面を見ている時に突然 /settings 誘導が現れる UX 不快感を回避)。
        // 手動 sync 時のみ recovery 提示 (= ユーザーの明示操作 = 復帰導線を見せる文脈)。
        if (this.isAutoSyncing) return
        // Issue #273: status に応じて recoveryButton を 2 mode で出し分け (= 同一ボタン DOM を mode で切り替えて共用)。
        // 401 → settings 誘導 / 5xx → retry / その他 (= 413/422) → 文言のみ (= 復帰導線が一意に決まらない)。
        if (response.status === 401) {
          this.showRecoveryButton("settings")
        } else if (is5xx) {
          this.showRecoveryButton("retry")
        }
        return
      }

      const result = await response.json()
      // Issue #276: 送信成功時に retry カウンタをリセット (= 次の 5xx で 1 回目挙動から再スタート)。
      this.retryCount = 0
      // Issue #314: 同期成功時刻を localStorage に記録 + UI 表示更新 (= 手動 / 自動どちらでも記録)。
      this.writeLastSync(new Date())
      this.updateLastSyncDisplay()
      // Issue #314: 自動同期時は status 文言を控えめに + home 遷移を抑止 (= 現在のページを邪魔しない UX 配慮)。
      if (this.isAutoSyncing) {
        this.showStatus(`✅ 自動同期完了 — ${result.accepted ?? 0} 件保存`)
        return
      }
      this.showStatus(`✅ 送信完了 — ${result.accepted ?? 0} 件保存。ホームを更新します...`)
      // Turbo で home 画面を再描画して、保存されたデータを反映 (= 手動 sync のみ、ユーザーの明示操作 = 遷移期待)。
      setTimeout(() => {
        if (typeof Turbo !== "undefined") {
          Turbo.visit("/")
        } else {
          window.location.assign("/")
        }
      }, 1500)
    } catch (error) {
      this.showStatus(`❌ 送信エラー: ${this.errorMessage(error)}`)
    } finally {
      this.syncButtonTarget.disabled = false
    }
  }

  // Issue #273: recoveryButton を mode 切替で表示。data-mode 属性 + 文言を JS で揃える。
  // **文言の SSOT は `RECOVERY_LABELS`、view 側初期 HTML (= settings mode 用) は SSR 用ダミー** (= JS が常に textContent を上書きするため)。
  // 将来 `RECOVERY_LABELS.settings` を変えると view 側の初期文言と乖離するが、ユーザー視認は JS 通過後なので実害なし。
  showRecoveryButton(mode) {
    if (!this.hasRecoveryButtonTarget) return
    const label = RECOVERY_LABELS[mode]
    if (!label) return
    this.recoveryButtonTarget.dataset.mode = mode
    this.recoveryButtonTarget.textContent = label
    this.recoveryButtonTarget.style.display = ""
  }

  // Issue #273: 401 (= settings 誘導) と 5xx (= retry) で同じボタンを 2 mode 共用。dataset.mode で分岐、想定外 mode は安全側 (= 何もしない) に倒す。
  // **本 PR は 2 mode で確定 (= 3 種類目 mode は v1.2 以降の検討、3 mode 追加時に `RECOVERY_ACTIONS` (= mode → callback) マップへ昇格検討)**。
  // 2 mode 限定では if-else で十分 (= YAGNI、3 回ルール待ち) = `feedback_explain_choices_to_beginner.md` の「3 回出てから抽象化」 と一致。
  recoveryAction(event) {
    const mode = event.currentTarget?.dataset?.mode
    if (mode === "settings") {
      // Issue #276: settings 遷移時は retry カウンタをリセット (= token 再生成で文脈が変わるため新規セッション扱い)。
      this.retryCount = 0
      if (typeof Turbo !== "undefined") {
        Turbo.visit("/settings")
      } else {
        window.location.assign("/settings")
      }
    } else if (mode === "retry") {
      this.sync()
    }
  }
}
