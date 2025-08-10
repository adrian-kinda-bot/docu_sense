import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="document-upload"
export default class extends Controller {
  static targets = ["file", "title"]

  prefillTitle() {
    const fileInput = this.hasFileTarget ? this.fileTarget : null
    const titleInput = this.hasTitleTarget ? this.titleTarget : null

    if (!fileInput || !titleInput) return
    if (!fileInput.files || fileInput.files.length === 0) return

    // Only prefill if user hasn't typed anything yet
    if (titleInput.dataset.userEdited === "true" && titleInput.value.trim().length > 0) return

    const fileName = fileInput.files[0].name || ""
    const baseName = fileName.replace(/\.[^/.]+$/, "")
    if (baseName) {
      titleInput.value = baseName
    }
  }

  markEdited() {
    if (this.hasTitleTarget) {
      this.titleTarget.dataset.userEdited = "true"
    }
  }
}


