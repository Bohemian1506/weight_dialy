import { Controller } from "@hotwired/stimulus"

// flash 自体は layout 側の <div class="fixed top-[calc(var(--navbar-height)+16px)] ... z-50"> 配下にあり document flow から外れているため、
// top offset は CSS 変数 --navbar-height (sketchy.css :root) で navbar 高さと連動する (= Issue #174 B)。
// 表示/消滅とも下のコンテンツがズレることはない。よって close() はシンプルな opacity フェード → remove で完結する。
// FOUC 対策: HTML 側で初期 opacity-0 + transition-opacity を仕込んでおき、connect() で次フレームに opacity-0
// を外す → 自然な fade-in。JS 無効環境では layout 側の <noscript> CSS で opacity:1 が強制適用され、flash が
// 永遠に不可視になる事故を防いでいる (= 進歩的拡張の本来形)。
// disconnect: Turbo navigation で element が外れたときに timeout が残らないよう両タイマーを clear。
// close: フェード中の SR 再読み防止に aria-hidden を立て、opacity-0 で fade-out させる。
// 二重 close 対策: this.closing で多重起動を抑制 (✕ を連打されても remove タイマーが多重発火しない)。
export default class extends Controller {
  connect() {
    this.closing = false
    requestAnimationFrame(() => {
      this.element.classList.remove("opacity-0")
    })
    this.timeout = setTimeout(() => this.close(), 3000)
  }

  disconnect() {
    clearTimeout(this.timeout)
    clearTimeout(this.removeTimeout)
  }

  close() {
    if (this.closing) return
    this.closing = true
    clearTimeout(this.timeout)
    this.element.setAttribute("aria-hidden", "true")
    this.element.classList.add("opacity-0")
    this.removeTimeout = setTimeout(() => this.element.remove(), 300)
  }
}
