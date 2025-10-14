import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "subcategorySelect", 
    "categoryDisplay", 
    "amountInput", 
    "lineAmountInput", 
    "lineSubcategoryInput",
    "form"
  ]

  connect() {
    console.log("TrxFormController connected")
  }

  updateCategory() {
    const selectedOption = this.subcategorySelectTarget.options[this.subcategorySelectTarget.selectedIndex]
    if (selectedOption.value) {
      // Find the category name from the option group
      const optgroup = selectedOption.parentElement
      const categoryName = optgroup.label
      this.categoryDisplayTarget.textContent = categoryName
      
      // Update the hidden line subcategory field
      this.lineSubcategoryInputTarget.value = selectedOption.value
      console.log('Subcategory selected:', selectedOption.value)
      console.log('Line subcategory input value set to:', this.lineSubcategoryInputTarget.value)
    } else {
      this.categoryDisplayTarget.textContent = '-'
      this.lineSubcategoryInputTarget.value = ''
    }
  }

  syncAmount() {
    // Set the line amount directly (TrxCreatorService will convert to cents)
    this.lineAmountInputTarget.value = this.amountInputTarget.value || 0
  }

  submitForm(event) {
    event.preventDefault()
    
    // Ensure line amount is set
    this.syncAmount()
    
    // Submit via fetch
    const formData = new FormData(this.formTarget)
    
    fetch(this.formTarget.action, {
      method: 'POST',
      body: formData,
      headers: {
        'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content,
        'Accept': 'application/json'
      }
    })
    .then(response => response.json())
    .then(data => {
      if (data.success) {
        // Reload the page to show the new transaction
        window.location.reload()
      } else {
        // Show errors
        alert('Error creating transaction: ' + (data.errors || 'Unknown error'))
      }
    })
    .catch(error => {
      console.error('Error:', error)
      alert('Error creating transaction. Please try again.')
    })
  }
}
