import { Controller } from "@hotwired/stimulus"

// flash メッセージを 3 秒後に自動で消す + 閉じるボタンで即時クローズする
// Turbo navigation で element が外れたときに timeout が残らないよう disconnect で clear
export default class extends Controller {
  connect() {
    this.timeout = setTimeout(() => this.close(), 3000)
  }

  disconnect() {
    clearTimeout(this.timeout)
  }

  close() {
    this.element.remove()
  }
}
