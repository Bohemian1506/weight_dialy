import { Controller } from "@hotwired/stimulus"

// @capgo/capacitor-health (v8.4.9) の HealthDataType 定義に合わせる。
// Health Connect 内部レコードは FloorsClimbedRecord だが、plugin の JS 公開 API は米国流の "flightsClimbed" (= 階段の段数)。
// 旧コードでは "floorsClimbed" と書かれており permission チェックで "Unsupported data type" エラーになっていた (2026-05-06 実機検証で発覚)。
const HEALTH_READ_TYPES = ["steps", "distance", "flightsClimbed"]

export default class extends Controller {
  static targets = ["status", "requestButton", "syncButton"]
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
      if (result?.granted) {
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
      if (result?.granted) {
        this.requestButtonTarget.style.display = "none"
        this.syncButtonTarget.style.display = ""
        await this.refreshData()
      } else {
        this.showStatus("⚠️ 権限が拒否されました。設定 → アプリ → Health Connect から許可できます")
      }
    } catch (error) {
      this.showStatus(`❌ リクエストエラー: ${this.errorMessage(error)}`)
    }
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
    if (!this.webhookTokenValue) {
      this.showStatus("⚠️ webhook token 未設定 (= ログインし直してください)")
      return
    }

    this.showStatus("📡 送信中...")
    this.syncButtonTarget.disabled = true

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
        let message = errorBody.slice(0, 80)
        try { message = JSON.parse(errorBody).error ?? message } catch (_) {}
        this.showStatus(`❌ 送信失敗 (HTTP ${response.status}): ${message}`)
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
}
