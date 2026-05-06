import { Controller } from "@hotwired/stimulus"

// 初回アクセス時のウェルカムモーダル制御。
// localStorage に「見た」フラグを保存し、2 回目以降は表示しない。
//
// 使い方:
//   <div data-controller="welcome-modal">
//     <div data-welcome-modal-target="overlay" style="display: none; ...">
//       ...モーダル内容...
//       <button data-action="click->welcome-modal#close">閉じる</button>
//     </div>
//   </div>
//
// 設計判断:
//   - localStorage を使う (= cookie / session より軽量、サーバ往復なし)
//   - localStorage 不可 (= プライベートブラウズ等) でも初回表示は走らせる (= 異常系で UX 悪化させない)
//   - キャッシュキーをアプリ名で名前空間化して将来の衝突回避

const STORAGE_KEY = "weight-daily:welcome-modal:seen"

export default class extends Controller {
  static targets = ["overlay"]

  connect() {
    if (this.alreadySeen()) return
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
    this.markSeen()
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

  alreadySeen() {
    try {
      return localStorage.getItem(STORAGE_KEY) === "true"
    } catch (_) {
      return false
    }
  }

  markSeen() {
    try {
      localStorage.setItem(STORAGE_KEY, "true")
    } catch (_) {
      // localStorage 不可環境ではフラグ保存できないが、モーダルは開閉できるので UX は壊れない
    }
  }
}
