import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    // Hide sidebar by default on mobile
    if (window.innerWidth < 1024) {
      this.hide()
    }
  }

  toggle() {
    if (this.element.classList.contains("hidden")) {
      this.show()
    } else {
      this.hide()
    }
  }

  show() {
    this.element.classList.remove("hidden")
    this.element.classList.add("absolute", "z-50", "h-full")
  }

  hide() {
    if (window.innerWidth < 1024) {
      this.element.classList.add("hidden")
    }
  }
}
