# Pin npm packages by running ./bin/importmap

pin "application"
pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
pin_all_from "app/javascript/controllers", under: "controllers"
pin "document-upload-controller", to: "controllers/document_upload_controller.js"
pin "modal-controller", to: "controllers/modal_controller.js"
pin "modal-trigger-controller", to: "controllers/modal_trigger_controller.js"
pin "drag_drop_upload", to: "drag_drop_upload.js"
