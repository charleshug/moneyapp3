import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["modal"]

  editVendor(event) {
    const vendorId = event.target.dataset.vendorId
    const vendorName = event.target.dataset.vendorName
    
    // Load the edit form via fetch
    fetch(`/vendors/${vendorId}/edit`, {
      headers: {
        'Accept': 'text/html',
        'X-Requested-With': 'XMLHttpRequest'
      }
    })
    .then(response => response.text())
    .then(html => {
      // Replace modal content
      const modalFrame = document.getElementById('modal')
      if (modalFrame) {
        modalFrame.innerHTML = html
        // Trigger modal open by finding the modal controller
        const modalElement = document.querySelector('[data-controller*="modal"]')
        if (modalElement && modalElement.controller) {
          modalElement.controller.open()
        }
      }
    })
    .catch(error => {
      console.error('Error loading vendor edit form:', error)
    })
  }
}
