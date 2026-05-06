import { Controller } from "@hotwired/stimulus"

// ウェルカムモーダル制御。
// デフォルトは毎回表示、ユーザーが「以降表示しない」チェックボックスを ON にした時のみ
// localStorage にフラグ保存して次回以降非表示にする (= UX: 見たくなったらまた見られる、見なくなりたい人だけ抑制)。
//
// 使い方:
//   <div data-controller="welcome-modal">
//     <div data-welcome-modal-target="overlay" style="display: none; ...">
//       ...モーダル内容...
//       <input type="checkbox" data-welcome-modal-target="dontShowAgain"> 以降表示しない
//       <button data-action="click->welcome-modal#close">閉じる</button>
//     </div>
//   </div>
//
// 設計判断:
//   - 「毎回表示 + opt-out」: 初回モーダル定石の「1 回限り」より、UX 自由度を優先 (= ユーザー局長判断)
//   - localStorage 不可 (= プライベートブラウズ等) でも閉じる動作は壊れない (= UX 異常系考慮)

const STORAGE_KEY = "weight-daily:welcome-modal:hidden"

export default class extends Controller {
  static targets = ["overlay", "dontShowAgain"]

  connect() {
    if (this.userOptedOut()) return
    this.show()
  }

  show() {
    this.overlayTarget.style.display = "flex"
    this.overlayTarget.setAttribute("aria-hidden", "false")
    this._keydownHandler = this.keydown.bind(this)
    window.addEventListener("keydown", this._keydownHandler)
  }

  close() {
    this.overlayTarget.style.display = "none"
    this.overlayTarget.setAttribute("aria-hidden", "true")
    if (this.hasDontShowAgainTarget && this.dontShowAgainTarget.checked) {
      this.markOptedOut()
    }
    if (this._keydownHandler) {
      window.removeEventListener("keydown", this._keydownHandler)
      this._keydownHandler = null
    }
  }

  // 背景 (overlay 自体) クリックで閉じる、内部の sketch-box クリックは無視
  backdropClose(event) {
    if (event.target === this.overlayTarget) {
      this.close()
    }
  }

  keydown(event) {
    if (event.key === "Escape") this.close()
  }

  userOptedOut() {
    try {
      return localStorage.getItem(STORAGE_KEY) === "true"
    } catch (_) {
      return false
    }
  }

  markOptedOut() {
    try {
      localStorage.setItem(STORAGE_KEY, "true")
    } catch (_) {
      // localStorage 不可環境ではフラグ保存できないが、モーダルは開閉できるので UX は壊れない
    }
  }
}
