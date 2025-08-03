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
      updateFileDisplay(files[0]);

      // Trigger change event for any existing listeners
      const event = new Event("change", { bubbles: true });
      fileInput.dispatchEvent(event);
    }
  }

  function updateFileDisplay(file) {
    // Create or update file info display
    let fileInfo = document.getElementById("file-info");

    if (!fileInfo) {
      fileInfo = document.createElement("div");
      fileInfo.id = "file-info";
      fileInfo.className = "mt-2 text-sm text-gray-600";
      uploadText.appendChild(fileInfo);
    }

    // Format file size
    const fileSize = (file.size / 1024 / 1024).toFixed(2);

    fileInfo.innerHTML = `
      <div class="flex items-center space-x-2">
        <svg class="h-5 w-5 text-green-500" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"></path>
        </svg>
        <span class="font-medium">${file.name}</span>
        <span class="text-gray-500">(${fileSize} MB)</span>
      </div>
    `;
  }

  // Also handle file input change for manual file selection
  fileInput.addEventListener("change", function (e) {
    if (this.files.length > 0) {
      updateFileDisplay(this.files[0]);
    }
  });
});
