import { Controller } from "@hotwired/stimulus"

const HEALTH_READ_TYPES = ["steps", "distance", "floorsClimbed"]

export default class extends Controller {
  static targets = ["status", "requestButton"]

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
        await this.refreshData()
      } else {
        this.showStatus("⏳ Health Connect の権限が必要です")
        this.requestButtonTarget.style.display = ""
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
        await this.refreshData()
      } else {
        this.showStatus("⚠️ 権限が拒否されました。設定 → アプリ → Health Connect から許可できます")
      }
    } catch (error) {
      this.showStatus(`❌ リクエストエラー: ${this.errorMessage(error)}`)
    }
  }

  showStatus(message) {
    this.statusTarget.textContent = message
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
      // README 注記より steps / distance は queryAggregated 対応、floorsClimbed は明記なし
      const [steps, distance, floors] = await Promise.all([
        this.queryAggregatedSafe(Health, "steps", startDate, endDate),
        this.queryAggregatedSafe(Health, "distance", startDate, endDate),
        this.queryAggregatedSafe(Health, "floorsClimbed", startDate, endDate)
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

  startOfTodayISO() {
    const d = new Date()
    d.setHours(0, 0, 0, 0)
    return d.toISOString()
  }

  todayISODate() {
    return new Date().toISOString().slice(0, 10)
  }

  formatSummary(data) {
    const steps = (data.step_count || 0).toLocaleString()
    const km = ((data.distance_meters || 0) / 1000).toFixed(2)
    const floors = data.floors_climbed || 0
    return `✅ 取得成功: ${steps} 歩 / ${km} km / ${floors} 階`
  }
}
