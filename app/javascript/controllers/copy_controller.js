import { Controller } from "@hotwired/stimulus"

// コピーボタン汎用コントローラー。
// data-copy-text-value にコピー対象テキストをセットし、
// data-action="click->copy#copy" をボタンに付けるだけで動く。
// クリック後 2 秒間「コピー済み✓」に切り替え、その後元のラベルに戻す。
// navigator.clipboard は HTTPS または localhost でのみ有効。HTTP 本番運用時は要確認。
export default class extends Controller {
  static values = { text: String }
  static targets = [ "button" ]

  copy() {
    navigator.clipboard.writeText(this.textValue).then(() => {
      this.#swapLabel("コピー済み✓", 2000)
    }).catch(() => {
      alert("コピーに失敗しました")
    })
  }

  // private

  #swapLabel(tempLabel, durationMs) {
    const btn = this.buttonTarget
    const original = btn.textContent
    btn.textContent = tempLabel
    clearTimeout(this.restoreTimeout)
    this.restoreTimeout = setTimeout(() => {
      btn.textContent = original
    }, durationMs)
  }

  disconnect() {
    clearTimeout(this.restoreTimeout)
  }
}
