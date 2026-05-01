import { Controller } from "@hotwired/stimulus"

// Turbo navigation で element が外れたときに timeout が残らないよう disconnect で clear。
// close() でも clearTimeout を呼んで明示的にタイマーを停止してから remove する。
export default class extends Controller {
  connect() {
    this.timeout = setTimeout(() => this.close(), 3000)
  }

  disconnect() {
    clearTimeout(this.timeout)
  }

  close() {
    clearTimeout(this.timeout)
    this.element.remove()
  }
}
