import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["menu"]

  connect() {
    // Close dropdown when clicking outside
    document.addEventListener("click", this.handleClickOutside.bind(this))
    // Close dropdown when pressing Escape
    document.addEventListener("keydown", this.handleKeydown.bind(this))
    // Close dropdown when window resizes
    window.addEventListener("resize", this.handleResize.bind(this))
  }

  disconnect() {
    document.removeEventListener("click", this.handleClickOutside.bind(this))
    document.removeEventListener("keydown", this.handleKeydown.bind(this))
    window.removeEventListener("resize", this.handleResize.bind(this))
  }

  toggle(event) {
    event.preventDefault()
    event.stopPropagation()

    if (this.menuTarget.classList.contains("hidden")) {
      this.show()
    } else {
      this.hide()
    }
  }

  show() {
    this.menuTarget.classList.remove("hidden")
  }

  hide(event) {
    if (event) {
      event.preventDefault()
      event.stopPropagation()
    }

    // Hide immediately
    this.menuTarget.classList.add("hidden")
  }

  handleClickOutside(event) {
    if (!this.element.contains(event.target)) {
      this.hide()
    }
  }

  // Close dropdown when pressing Escape
  handleKeydown(event) {
    if (event.key === 'Escape') {
      this.hide()
    }
  }

  // Close dropdown when window resizes
  handleResize() {
    this.hide()
  }
}
