import { Controller } from "@hotwired/stimulus"

// flash 自体は layout 側の <div class="fixed top-20 ... z-50"> 配下にあり document flow から外れているため、
// 消えても下のコンテンツがズレることはない。よって close() はシンプルな opacity フェード → remove で完結する。
// Turbo navigation で element が外れたときに timeout が残らないよう disconnect で両タイマーを clear。
// 二重 close 対策: this.closing で多重起動を抑制 (✕ を連打されても remove タイマーが多重発火しない)。
export default class extends Controller {
  connect() {
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
    this.element.classList.add("opacity-0", "transition-opacity", "duration-300")
    this.removeTimeout = setTimeout(() => this.element.remove(), 300)
  }
}
