import { Controller } from "@hotwired/stimulus"

// Phase 3 Capacitor OAuth ブリッジの起点 (= WebView 側)。
// Web 版では何もせず通常 POST フローのまま (Stimulus controller は no-op)。
// Capacitor アプリ内では login button の click を奪い、@capacitor/browser で
// Custom Tabs に /auth/capacitor_start を開いて OAuth ブリッジを開始する。
//
// 重要: Custom Tabs と WebView は cookie storage が分離するため、ボタンの form submit を
// そのまま走らせると WebView 側 cookie に session ができても OAuth は Custom Tabs で動くので無意味。
// click を完全に止めて Browser.open だけ走らせるのが正解。
export default class extends Controller {
  static values = { startUrl: { type: String, default: "/auth/capacitor_start" } }

  intercept(event) {
    if (typeof window.Capacitor === "undefined" || !window.Capacitor.isNativePlatform?.()) {
      return // Web 版は通常の form POST に任せる
    }

    const Browser = window.Capacitor.Plugins.Browser
    if (!Browser || typeof Browser.open !== "function") {
      console.warn("[Capacitor] Browser plugin not registered, falling back to web POST")
      return
    }

    event.preventDefault()
    event.stopPropagation()

    const origin = window.location.origin
    const fullUrl = origin + this.startUrlValue
    // toolbarColor で Custom Tabs のアドレスバーをブランドカラー (= --accent / sketch-btn-primary 背景) に揃える。
    // Android では Chrome Custom Tabs に反映、iOS では SFSafariViewController で無視されるが副作用はない。
    Browser.open({ url: fullUrl, toolbarColor: "#ff7a45" }).catch((error) => {
      console.error("[Capacitor] Browser.open failed:", error)
    })
  }
}
