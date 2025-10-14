// app/javascript/controllers/modal_controller.js

import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  // Add a target for the inner content wrapper
  static targets = ["container", "contentWrapper"] 

  connect() {
    // Only auto-open if this is a new modal (not loaded via turbo frame)
    if (!this.element.querySelector('turbo-frame[id="modal"]')) {
      this.open()
    }
    // 💡 Add keyboard close for better UX
    this.boundCloseOnEscape = this.closeOnEscape.bind(this)
    document.addEventListener("keydown", this.boundCloseOnEscape)
    
    // Listen for turbo frame loads to auto-open modal
    this.boundTurboFrameLoad = this.handleTurboFrameLoad.bind(this)
    document.addEventListener("turbo:frame-load", this.boundTurboFrameLoad)
  }

  // Method to open modal when content is loaded via turbo stream
  openModal() {
    this.open()
  }

  // Handle turbo stream load events
  handleTurboLoad() {
    // Small delay to ensure the modal is fully rendered
    setTimeout(() => {
      this.open()
    }, 10)
  }

  // Handle turbo frame load events
  handleTurboFrameLoad(event) {
    // Check if the loaded frame is the modal frame
    if (event.target.id === 'modal' && event.target.innerHTML.trim() !== '') {
      // Small delay to ensure the modal content is fully rendered
      setTimeout(() => {
        this.open()
      }, 10)
    }
  }


  disconnect() {
    document.removeEventListener("keydown", this.boundCloseOnEscape)
    document.removeEventListener("turbo:frame-load", this.boundTurboFrameLoad)
  }

  open() {
    this.element.classList.remove("hidden")
    this.element.classList.add("flex")
  }

  close() {
    this.element.classList.add("hidden")
    this.element.classList.remove("flex")
    
    // ➡️ NEW: Clear the content when the modal is closed
    this.clearContent()
    
    // ➡️ NEW: Replace the modal turbo frame with empty content
    const modalFrame = document.querySelector('turbo-frame[id="modal"]')
    if (modalFrame) {
      modalFrame.innerHTML = ""
    }
  }

  // ➡️ NEW: Method to clear the HTML content
  clearContent() {
    // Check if the contentWrapper target exists before trying to clear it
    if (this.hasContentWrapperTarget) {
      this.contentWrapperTarget.innerHTML = ""
    }
  }

  // Only close when clicking the background (not the modal content)
  hideOnBackgroundClick(e) {
    if (e.target === this.element) {
      this.close()
    }
  }

  // New: Method for closing with the Escape key
  closeOnEscape(event) {
    if (event.key === "Escape") {
      this.close()
    }
  }
}