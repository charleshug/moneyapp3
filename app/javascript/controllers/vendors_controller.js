import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  selectVendor(event) {
    const vendorId = event.currentTarget.dataset.vendorId
    const vendorName = event.currentTarget.dataset.vendorName
    
    // Remove active class from all vendor items
    this.element.querySelectorAll('[data-vendor-id]').forEach(item => {
      item.classList.remove('bg-blue-100', 'border-blue-300')
      item.classList.add('hover:bg-blue-100')
    })
    
    // Add active class to selected vendor
    event.currentTarget.classList.add('bg-blue-100', 'border-blue-300')
    event.currentTarget.classList.remove('hover:bg-blue-100')
    
    // Load the vendor form in the right side
    this.loadVendorForm(vendorId)
  }
  
  loadVendorForm(vendorId) {
    const formContainer = document.getElementById('vendor-form-container')
    if (!formContainer) return
    
    // Show loading state
    formContainer.innerHTML = `
      <div class="flex items-center justify-center h-full">
        <div class="text-center">
          <div class="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600 mx-auto mb-4"></div>
          <p class="text-gray-500">Loading...</p>
        </div>
      </div>
    `
    
    // Use Turbo to load the form
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
        throw new Error('Failed to load vendor form')
      }
    })
    .then(html => {
      // Use Turbo to process the stream
      Turbo.renderStreamMessage(html)
    })
    .catch(error => {
      console.error('Error loading vendor form:', error)
      formContainer.innerHTML = `
        <div class="flex items-center justify-center h-full text-red-500">
          <div class="text-center">
            <p class="text-lg font-medium">Error loading vendor form</p>
            <p class="text-sm text-gray-500 mt-2">Please try again</p>
          </div>
        </div>
      `
    })
  }
  
  loadNewVendorForm(event) {
    event.preventDefault()
    
    const formContainer = document.getElementById('vendor-form-container')
    if (!formContainer) return
    
    // Show loading state
    formContainer.innerHTML = `
      <div class="flex items-center justify-center h-full">
        <div class="text-center">
          <div class="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600 mx-auto mb-4"></div>
          <p class="text-gray-500">Loading...</p>
        </div>
      </div>
    `
    
    // Use Turbo to load the new vendor form
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
      // Use Turbo to process the stream
      Turbo.renderStreamMessage(html)
    })
    .catch(error => {
      console.error('Error loading new vendor form:', error)
      formContainer.innerHTML = `
        <div class="flex items-center justify-center h-full text-red-500">
          <div class="text-center">
            <p class="text-lg font-medium">Error loading new vendor form</p>
            <p class="text-sm text-gray-500 mt-2">Please try again</p>
          </div>
        </div>
      `
    })
  }
}
