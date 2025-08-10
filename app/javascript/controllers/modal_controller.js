import { Controller } from "@hotwired/stimulus"

// A simple modal controller. Attach `data-controller="modal"` to a wrapper
// or the overlay itself. Provide optional targets:
// - panel: the overlay element to show/hide (falls back to this.element)
// - content: the inner modal content to prevent backdrop close when clicking inside
export default class extends Controller {
  static targets = ["panel", "content"]

  connect() {
    this.handleBackdropClick = this.handleBackdropClick.bind(this)
    this.handleKeydown = this.handleKeydown.bind(this)
    this.panelElement.addEventListener("click", this.handleBackdropClick)
    document.addEventListener("keydown", this.handleKeydown)
  }

  disconnect() {
    this.panelElement.removeEventListener("click", this.handleBackdropClick)
    document.removeEventListener("keydown", this.handleKeydown)
  }

  show() {
    this.panelElement.classList.remove("hidden")
  }

  hide() {
    this.panelElement.classList.add("hidden")
  }

  handleBackdropClick(event) {
    // If clicked directly on the backdrop (not inside modal content), hide
    if (this.hasContentTarget) {
      if (!this.contentTarget.contains(event.target)) {
        this.hide()
      }
    } else {
      // No content target provided; any click on panel closes
      if (event.target === this.panelElement) this.hide()
    }
  }

  get panelElement() {
    return this.hasPanelTarget ? this.panelTarget : this.element
  }

  handleKeydown(event) {
    if (event.key === "Escape") {
      if (!this.panelElement.classList.contains("hidden")) {
        this.hide()
      }
    }
  }
}
