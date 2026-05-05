import { Controller } from "@hotwired/stimulus"

// 退会確認モーダルを制御する Stimulus controller。
//
// 使い方:
//   data-controller="confirm-deletion"
//   data-confirm-deletion-expected-name-value="<%= current_user.name %>"
//
// 教材メモ: 不可逆操作の UX パターンとして「名前入力一致確認」を採用 (= GitHub 方式)。
// disabled 解除は input イベントのたびにリアルタイム比較するため、コピペも検出できる。
export default class extends Controller {
  static targets = ["modal", "input", "submitButton"]
  static values  = { expectedName: String }

  // モーダルを開く
  openModal() {
    this.modalTarget.style.display = "flex"
    this.modalTarget.setAttribute("aria-hidden", "false")
    this.inputTarget.value = ""
    this.submitButtonTarget.disabled = true
    // フォーカスをインプットに移動しアクセシビリティを確保
    this.inputTarget.focus()
  }

  // モーダルを閉じる
  closeModal() {
    this.modalTarget.style.display = "none"
    this.modalTarget.setAttribute("aria-hidden", "true")
    this.inputTarget.value = ""
    this.submitButtonTarget.disabled = true
  }

  // input イベント: 入力値と期待名を比較してボタンの disabled を制御
  checkInput() {
    const matched = this.inputTarget.value.trim() === this.expectedNameValue.trim()
    this.submitButtonTarget.disabled = !matched
  }

  // オーバーレイ (背景) クリックでモーダルを閉じる
  backdropClose(event) {
    if (event.target === this.modalTarget) {
      this.closeModal()
    }
  }

  // ESC キーでモーダルを閉じる
  keydown(event) {
    if (event.key === "Escape") {
      this.closeModal()
    }
  }
}
