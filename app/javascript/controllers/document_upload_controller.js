import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="document-upload"
export default class extends Controller {
  static targets = [
    "file",
    "title",
    "defaultState",
    "selectedState",
    "fileName",
    "dropzone",
    "error",
    "removeFlag"
  ]

  prefillTitle() {
    const fileInput = this.hasFileTarget ? this.fileTarget : null
    const titleInput = this.hasTitleTarget ? this.titleTarget : null

    if (!fileInput || fileInput.files.length === 0) return

    const fileName = fileInput.files[0].name || ""

    // Update UI state to show selected file regardless of title editing
    this.showSelectedState(fileName)

    // Only prefill if user hasn't typed anything yet
    if (titleInput && !(titleInput.dataset.userEdited === "true" && titleInput.value.trim().length > 0)) {
      const baseName = fileName.replace(/\.[^/.]+$/, "")
      if (baseName) {
        titleInput.value = baseName
      }
    }
  }

  markEdited() {
    if (this.hasTitleTarget) {
      this.titleTarget.dataset.userEdited = "true"
    }
  }

  showSelectedState(fileName) {
    if (this.hasDefaultStateTarget) this.defaultStateTarget.classList.add("hidden")
    if (this.hasSelectedStateTarget) this.selectedStateTarget.classList.remove("hidden")
    if (this.hasFileNameTarget) this.fileNameTarget.textContent = fileName
    if (this.hasDropzoneTarget) {
      this.dropzoneTarget.classList.remove("border-gray-300", "border-dashed", "border-red-300")
      this.dropzoneTarget.classList.add("border-emerald-300")
    }
    this.clearError()
    if (this.hasRemoveFlagTarget) this.removeFlagTarget.value = "false"
  }

  showDefaultState() {
    if (this.hasDefaultStateTarget) this.defaultStateTarget.classList.remove("hidden")
    if (this.hasSelectedStateTarget) this.selectedStateTarget.classList.add("hidden")
    if (this.hasFileNameTarget) this.fileNameTarget.textContent = ""
    if (this.hasDropzoneTarget) {
      this.dropzoneTarget.classList.remove("border-emerald-300", "border-red-300")
      this.dropzoneTarget.classList.add("border-gray-300", "border-dashed")
    }
    this.clearError()
  }

  unattach() {
    if (this.hasFileTarget) {
      this.fileTarget.value = ""
    }
    if (this.hasRemoveFlagTarget) {
      this.removeFlagTarget.value = "true"
    }
    this.showDefaultState()
  }

  validate(event) {
    const hasNewFile = this.hasFileTarget && this.fileTarget.files && this.fileTarget.files.length > 0
    const wantsRemoval = this.hasRemoveFlagTarget && this.removeFlagTarget.value === "true"

    // If there is neither an existing file kept nor a new one selected, block submit
    // On new page, wantsRemoval will be false and hasNewFile must be true
    if (!hasNewFile && wantsRemoval) {
      event.preventDefault()
      this.showError("Please attach a file or cancel removal.")
      return
    }

    // On new page where removeFlag is absent: require a file
    if (!hasNewFile && !this.hasRemoveFlagTarget) {
      event.preventDefault()
      this.showError("Please attach a file before uploading.")
    }
  }

  showError(message) {
    if (this.hasErrorTarget) {
      this.errorTarget.textContent = message
      this.errorTarget.classList.remove("hidden")
    }
    if (this.hasDropzoneTarget) {
      this.dropzoneTarget.classList.remove("border-gray-300", "border-emerald-300")
      this.dropzoneTarget.classList.add("border-red-300")
    }
  }

  clearError() {
    if (this.hasErrorTarget) {
      this.errorTarget.textContent = ""
      this.errorTarget.classList.add("hidden")
    }
    if (this.hasDropzoneTarget) {
      this.dropzoneTarget.classList.remove("border-red-300")
    }
  }
}


