import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    // Listen for turbo stream events to clear selection after operations
    this.boundTurboStreamEnd = this.handleTurboStreamEnd.bind(this)
    document.addEventListener("turbo:stream-end", this.boundTurboStreamEnd)
    
    // Listen for form submission to capture vendor ID before update
    this.boundFormSubmit = this.handleFormSubmit.bind(this)
    document.addEventListener("turbo:submit-end", this.boundFormSubmit)
    
    // Use event delegation for vendor item clicks
    this.boundVendorClick = this.handleVendorClick.bind(this)
    this.element.addEventListener("click", this.boundVendorClick)
  }
  
  disconnect() {
    document.removeEventListener("turbo:stream-end", this.boundTurboStreamEnd)
    document.removeEventListener("turbo:submit-end", this.boundFormSubmit)
    this.element.removeEventListener("click", this.boundVendorClick)
  }
  
  handleFormSubmit(event) {
    // Store the vendor ID when form is submitted (before the DOM is updated)
    if (this.currentSelectedVendorId) {
      this.pendingVendorId = this.currentSelectedVendorId
    }
  }
  
  handleTurboStreamEnd(event) {
    // Use the pending vendor ID from form submission
    const selectedVendorId = this.pendingVendorId || this.currentSelectedVendorId
    
    // Store scroll position before clearing selection
    const scrollContainer = this.element.closest('.overflow-y-auto')
    const scrollPosition = scrollContainer ? scrollContainer.scrollTop : 0
    
    // Clear selection after successful operations
    setTimeout(() => {
      this.clearSelection()
      // Re-establish event listeners for the updated vendor list
      this.reconnectEventListeners()
      // Restore scroll position
      if (scrollContainer) {
        scrollContainer.scrollTop = scrollPosition
      }
      // Re-select the vendor that was just edited if it exists
      if (selectedVendorId) {
        this.reselectVendor(selectedVendorId)
      }
      // Clear the pending vendor ID
      this.pendingVendorId = null
    }, 100)
  }
  
  handleVendorClick(event) {
    // Check if the clicked element is a vendor item or inside one
    const vendorItem = event.target.closest('.vendor-item')
    
    if (vendorItem) {
      event.preventDefault()
      this.selectVendor(vendorItem)
    }
  }
  
  selectVendor(vendorItem) {
    const vendorId = vendorItem.dataset.vendorId
    const vendorName = vendorItem.dataset.vendorName
    
    // Store the selected vendor ID for later restoration
    this.currentSelectedVendorId = vendorId
    
    // Remove active class from all vendor items
    const allItems = this.element.querySelectorAll('.vendor-item')
    allItems.forEach(item => {
      item.classList.remove('bg-blue-100', 'border-blue-300', 'border-l-4')
      item.classList.add('hover:bg-blue-100')
    })
    
    // Add active class to selected vendor
    vendorItem.classList.add('bg-blue-100', 'border-blue-300', 'border-l-4')
    vendorItem.classList.remove('hover:bg-blue-100')
    
    // Load the vendor form in the right side
    this.loadVendorForm(vendorId)
  }
  
  loadVendorForm(vendorId) {
    // Use Turbo to load the form directly
    fetch(`/vendors/${vendorId}/edit`, {
      headers: {
        'Accept': 'text/vnd.turbo-stream.html',
        'X-Requested-With': 'XMLHttpRequest'
      }
    })
    .then(response => {
      if (response.ok) {
        return response.text()
      } else {
        throw new Error(`Failed to load vendor form: ${response.status} ${response.statusText}`)
      }
    })
    .then(html => {
      // Use Turbo to process the stream - this will update the form container
      Turbo.renderStreamMessage(html)
    })
    .catch(error => {
      console.error('Error loading vendor form:', error)
    })
  }
  
  loadNewVendorForm(event) {
    event.preventDefault()
    
    // Clear any selected vendor
    this.clearSelection()
    this.currentSelectedVendorId = null
    
    // Use Turbo to load the new vendor form directly
    fetch('/vendors/new', {
      headers: {
        'Accept': 'text/vnd.turbo-stream.html',
        'X-Requested-With': 'XMLHttpRequest'
      }
    })
    .then(response => {
      if (response.ok) {
        return response.text()
      } else {
        throw new Error('Failed to load new vendor form')
      }
    })
    .then(html => {
      // Use Turbo to process the stream - this will replace the form container
      Turbo.renderStreamMessage(html)
    })
    .catch(error => {
      console.error('Error loading new vendor form:', error)
    })
  }
  
  clearSelection() {
    // Remove active class from all vendor items
    this.element.querySelectorAll('.vendor-item').forEach(item => {
      item.classList.remove('bg-blue-100', 'border-blue-300', 'border-l-4')
      item.classList.add('hover:bg-blue-100')
    })
  }
  
  reconnectEventListeners() {
    // Remove existing event listener to avoid duplicates
    this.element.removeEventListener("click", this.boundVendorClick)
    // Re-add the event listener for the updated vendor list
    this.element.addEventListener("click", this.boundVendorClick)
  }
  
  reselectVendor(vendorId) {
    // Find the vendor item with the matching ID in the updated list
    const vendorItem = this.element.querySelector(`[data-vendor-id="${vendorId}"]`)
    if (vendorItem) {
      // Apply the selection styling
      vendorItem.classList.add('bg-blue-100', 'border-blue-300', 'border-l-4')
      vendorItem.classList.remove('hover:bg-blue-100')
    }
  }
}
