import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "datalist", "hiddenInput"]
  static values = { 
    searchUrl: String,
    budgetId: String
  }

  connect() {
    this.debounceTimer = null
    this.vendors = []
    this.vendorsLoaded = false
  }

  loadInitialVendors() {
    if (this.vendorsLoaded) return
    
    fetch(`${this.searchUrlValue}?budget_id=${this.budgetIdValue}`)
      .then(response => response.json())
      .then(data => {
        this.vendors = data.vendors || []
        this.vendorsLoaded = true
        this.updateDatalist()
      })
      .catch(error => console.error('Error loading vendors:', error))
  }

  search() {
    clearTimeout(this.debounceTimer)
    this.debounceTimer = setTimeout(() => {
      const query = this.inputTarget.value.trim()
      
      if (query.length === 0) {
        this.loadInitialVendors()
        return
      }

      // Load vendors if not already loaded
      if (!this.vendorsLoaded) {
        this.loadInitialVendors()
        return
      }

      fetch(`${this.searchUrlValue}?budget_id=${this.budgetIdValue}&q=${encodeURIComponent(query)}`)
        .then(response => response.json())
        .then(data => {
          this.vendors = data.vendors || []
          this.updateDatalist()
        })
        .catch(error => console.error('Error searching vendors:', error))
    }, 300)
  }

  updateDatalist() {
    this.datalistTarget.innerHTML = ''
    
    this.vendors.forEach(vendor => {
      const option = document.createElement('option')
      option.value = vendor.name
      option.dataset.vendorId = vendor.id
      this.datalistTarget.appendChild(option)
    })
  }

  onInputChange() {
    const inputValue = this.inputTarget.value.trim()
    
    // Find matching vendor by name
    const matchingVendor = this.vendors.find(vendor => 
      vendor.name.toLowerCase() === inputValue.toLowerCase()
    )
    
    if (matchingVendor) {
      this.hiddenInputTarget.value = matchingVendor.id
    } else {
      // Clear the hidden input if no exact match
      this.hiddenInputTarget.value = ''
    }
  }

  onFocus() {
    // Load all vendors when focusing on the input
    this.loadInitialVendors()
  }
}
