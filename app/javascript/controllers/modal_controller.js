import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["content"]

  connect() {
    // Close modal when pressing Escape
    document.addEventListener("keydown", this.handleKeydown.bind(this))
  }

  disconnect() {
    document.removeEventListener("keydown", this.handleKeydown.bind(this))
  }

  show() {
    this.element.classList.remove("hidden")
  }

  hide() {
    this.element.classList.add("hidden")
  }

  handleKeydown(event) {
    if (event.key === "Escape") {
      this.hide()
    }
  }
}
