import { Controller } from "@hotwired/stimulus"

// scroll 位置に応じて navbar に .is-scrolled class を付与し、CSS で box-shadow (浮遊感) を表現する。
//
// throttle: rAF (requestAnimationFrame) を使い、1 フレームごとに最大 1 回だけ DOM 操作を走らせる。
// scroll イベントが 60fps 超で発火しても rAF キューが詰まるだけで DOM 更新は 1 フレーム 1 回。
// THRESHOLD = 4px: 意図しない誤検知 (= inertia スクロールの微小バウンス) を無視する最小値。
//
// disconnect: page を離れた / Turbo navigation で element が外れたときに
// scroll リスナーを確実に除去してメモリリークを防ぐ。
export default class extends Controller {
  static THRESHOLD = 4

  connect() {
    this.ticking = false
    this.onScroll = this.handleScroll.bind(this)
    window.addEventListener("scroll", this.onScroll, { passive: true })
    // 初期状態をページリロード時にも正しく反映する
    this.updateClass()
  }

  disconnect() {
    window.removeEventListener("scroll", this.onScroll)
  }

  handleScroll() {
    if (this.ticking) return
    this.ticking = true
    requestAnimationFrame(() => {
      this.updateClass()
      this.ticking = false
    })
  }

  updateClass() {
    if (window.scrollY > this.constructor.THRESHOLD) {
      this.element.classList.add("is-scrolled")
    } else {
      this.element.classList.remove("is-scrolled")
    }
  }
}
