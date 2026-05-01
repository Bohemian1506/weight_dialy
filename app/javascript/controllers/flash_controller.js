import { Controller } from "@hotwired/stimulus"

// flash 自体は layout 側の <div class="fixed top-24 ... z-50"> 配下にあり document flow から外れているため、
// 表示/消滅とも下のコンテンツがズレることはない。よって close() はシンプルな opacity フェード → remove で完結する。
// 入りアニメ: HTML 側で初期 opacity-0 + transition-opacity を仕込んでおき、connect() で次フレームに
// opacity-0 を外す → 自然に fade-in する (進歩的拡張: JS が動かない場合は flash が見えないが、自動消滅も
// JS 必須なので運用上の縮退として許容)。
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
