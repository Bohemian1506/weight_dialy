import { Controller } from "@hotwired/stimulus"

// @capgo/capacitor-health (v8.4.9) の HealthDataType 定義に合わせる。
// Health Connect 内部レコードは FloorsClimbedRecord だが、plugin の JS 公開 API は米国流の "flightsClimbed" (= 階段の段数)。
// 旧コードでは "floorsClimbed" と書かれており permission チェックで "Unsupported data type" エラーになっていた (2026-05-06 実機検証で発覚)。
const HEALTH_READ_TYPES = ["steps", "distance", "flightsClimbed"]

// HTTP status 別の日本語フォールバック (Issue #138)。
// カジュアル層に「HTTP 422」 「Unauthorized」 が伝わらないため、想定 status 6 種に日本語を当てる。
// 想定外 status (= 404 / 429 等) は呼び出し側で `HTTP ${status}` に fallback。
// 401 のみ recoveryButton で「設定ページでトークン再生成」 への動線を提供 (= キーワード「トークン再生成」 を文言・ボタン文言・誘導先で統一)。
const STATUS_MESSAGES = {
  401: "トークンが無効です。設定ページでトークンを再生成してください",
  413: "送信データが多すぎます。しばらく待ってから再試行してください",
  422: "データの形式に問題があります",
  500: "サーバー側のエラーです。しばらく待ってから再試行してください",
  502: "サーバーが応答しません。ネットワーク接続を確認してください",
  503: "サーバーが混み合っています。しばらく待ってから再試行してください"
}

export default class extends Controller {
  static targets = ["status", "requestButton", "syncButton", "recoveryButton"]
  static values = { webhookToken: String }

  connect() {
    if (!this.isCapacitorNative()) {
      return
    }
    this.element.style.display = ""
    this.checkPermission().catch((error) => {
      this.showStatus(`❌ 初期化エラー: ${this.errorMessage(error)}`)
    })
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
        // HTTP status 別の日本語フォールバック (Issue #138)。STATUS_MESSAGES にあれば優先、
        // なければ従来通り `HTTP ${status}: ${body 抜粋}` で開発者 dogfood 互換。
        const friendlyMessage = STATUS_MESSAGES[response.status]
        const display = friendlyMessage
          ? `❌ ${friendlyMessage}`
          : `❌ 送信失敗 (HTTP ${response.status}): ${bodyMessage}`
        this.showStatus(display)
        // 401 (= token 無効) のときのみ Settings 誘導ボタンを表示 (= 復帰導線が一意に決まる status のため)。
        // 他 status (= 5xx の retry 系等) の復帰導線は本 PR スコープ外、必要になったら別 Issue で recoveryButton を 2 mode 化検討。
        if (response.status === 401 && this.hasRecoveryButtonTarget) {
          this.recoveryButtonTarget.style.display = ""
        }
        return
      }

      const result = await response.json()
      this.showStatus(`✅ 送信完了 — ${result.accepted ?? 0} 件保存。ホームを更新します...`)
      // Turbo で home 画面を再描画して、保存されたデータを反映
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

  // 401 検出時に表示される Settings 誘導ボタンの遷移ハンドラ (Issue #138)。
  // Turbo がロード済なら Turbo.visit、そうでなければ window.location で /settings へ遷移。
  openSettings() {
    if (typeof Turbo !== "undefined") {
      Turbo.visit("/settings")
    } else {
      window.location.assign("/settings")
    }
  }
}
