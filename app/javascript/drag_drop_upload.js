document.addEventListener("DOMContentLoaded", function () {
  const dropZone = document.querySelector(".border-dashed");
  const fileInput = document.getElementById("document_file");
  const uploadText = document.querySelector(".text-center");

  if (!dropZone || !fileInput) return;

  // Prevent default drag behaviors
  ["dragenter", "dragover", "dragleave", "drop"].forEach(eventName => {
    dropZone.addEventListener(eventName, preventDefaults, false);
    document.body.addEventListener(eventName, preventDefaults, false);
  });

  // Highlight drop zone when item is dragged over it
  ["dragenter", "dragover"].forEach(eventName => {
    dropZone.addEventListener(eventName, highlight, false);
  });

  ["dragleave", "drop"].forEach(eventName => {
    dropZone.addEventListener(eventName, unhighlight, false);
  });

  // Handle dropped files
  dropZone.addEventListener("drop", handleDrop, false);

  function preventDefaults(e) {
    e.preventDefault();
    e.stopPropagation();
  }

  function highlight(e) {
    dropZone.classList.add("border-blue-400", "bg-blue-50");
  }

  function unhighlight(e) {
    dropZone.classList.remove("border-blue-400", "bg-blue-50");
  }

  function handleDrop(e) {
    const dt = e.dataTransfer;
    const files = dt.files;

    if (files.length > 0) {
      fileInput.files = files;

      // Update the display to show selected file
      // Trigger change event for any existing listeners
      const event = new Event("change", { bubbles: true });
      fileInput.dispatchEvent(event);
    }
  }
});
