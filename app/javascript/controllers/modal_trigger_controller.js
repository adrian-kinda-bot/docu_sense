import { Controller } from "@hotwired/stimulus"

// Simple launcher that opens a modal by element id
// Usage: data-controller="modal-trigger" data-modal-trigger-target-id="modalElementId"
export default class extends Controller {
  open() {
    const targetId = this.element.dataset.modalTriggerTargetId
    if (!targetId) return
    const modalEl = document.getElementById(targetId)
    if (!modalEl) return
    modalEl.classList.remove("hidden")
  }
}


