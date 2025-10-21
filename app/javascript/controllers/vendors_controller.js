import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    // Listen for turbo stream events to clear selection after operations
    this.boundTurboStreamEnd = this.handleTurboStreamEnd.bind(this)
    document.addEventListener("turbo:stream-end", this.boundTurboStreamEnd)
    
    // Use event delegation for vendor item clicks
    this.boundVendorClick = this.handleVendorClick.bind(this)
    this.element.addEventListener("click", this.boundVendorClick)
  }
  
  disconnect() {
    document.removeEventListener("turbo:stream-end", this.boundTurboStreamEnd)
    this.element.removeEventListener("click", this.boundVendorClick)
  }
  
  handleTurboStreamEnd(event) {
    // Clear selection after successful operations
    setTimeout(() => {
      this.clearSelection()
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
}
