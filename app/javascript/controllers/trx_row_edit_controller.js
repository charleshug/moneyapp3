import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["field", "input", "display", "controlRow", "submitButton", "cancelButton"]
  static values = { 
    trxId: String
  }

  connect() {
    this.isEditing = false
    this.fieldControllers = new Map()
    this.originalValues = new Map()
  }

  // Handle single click to prevent row selection
  handleClick(event) {
    event.stopPropagation()
  }

  // Start editing mode for the entire row
  startEdit(event) {
    if (event) {
      event.preventDefault()
      event.stopPropagation()
    }
    
    if (this.isEditing) return
    
    this.isEditing = true
    this.showAllInputs()
    this.showControlRow()
    this.focusFirstInput()
  }

  // Cancel editing mode
  cancelEdit(event) {
    if (event) {
      event.preventDefault()
      event.stopPropagation()
    }
    
    this.isEditing = false
    this.resetAllValues()
    this.showAllDisplays()
    this.hideControlRow()
    this.removeEditingRowClass()
  }

  // Save all changes
  saveEdit(event) {
    if (event) {
      event.preventDefault()
      event.stopPropagation()
    }
    
    this.updateTransaction()
  }

  // Handle keyboard events
  handleKeydown(event) {
    if (event.key === 'Enter') {
      event.preventDefault()
      this.saveEdit(event)
    } else if (event.key === 'Escape') {
      event.preventDefault()
      event.stopPropagation()
      this.cancelEdit(event)
    }
  }

  // Show all input fields
  showAllInputs() {
    this.inputTargets.forEach(input => {
      input.classList.remove('hidden')
    })
    this.displayTargets.forEach(display => {
      display.classList.add('hidden')
    })
  }

  // Show all display fields
  showAllDisplays() {
    this.inputTargets.forEach(input => {
      input.classList.add('hidden')
    })
    this.displayTargets.forEach(display => {
      display.classList.remove('hidden')
    })
  }

  // Show control row
  showControlRow() {
    this.controlRowTarget.classList.remove('hidden')
  }

  // Hide control row
  hideControlRow() {
    this.controlRowTarget.classList.add('hidden')
  }

  // Focus first input
  focusFirstInput() {
    setTimeout(() => {
      if (this.inputTargets.length > 0) {
        this.inputTargets[0].focus()
        this.inputTargets[0].select()
      }
    }, 10)
  }

  // Reset all values to original
  resetAllValues() {
    this.inputTargets.forEach((input, index) => {
      const display = this.displayTargets[index]
      if (display) {
        input.value = display.textContent.trim()
      }
    })
  }

  // Update transaction with all field values
  updateTransaction() {
    const formData = new FormData()
    
    // Get all field values
    const fieldData = this.collectFieldData()
    
    // Add transaction data
    formData.append('trx[cleared]', fieldData.cleared)
    formData.append('trx[memo]', fieldData.memo)
    formData.append('trx[date]', fieldData.date)
    formData.append('trx[vendor_custom_text]', fieldData.vendor)
    
    // Add line attributes for amount
    if (fieldData.amount) {
      formData.append('trx[lines_attributes][0][amount]', (parseFloat(fieldData.amount) * 100).toString())
      formData.append('trx[lines_attributes][0][id]', fieldData.lineId || '')
      formData.append('trx[lines_attributes][0][ledger_id]', fieldData.ledgerId || '')
      formData.append('trx[lines_attributes][0][subcategory_form_id]', fieldData.subcategoryId || '')
    }

    fetch(`/trxes/${this.trxIdValue}`, {
      method: 'PATCH',
      body: formData,
      headers: {
        'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content,
        'Accept': 'application/json'
      }
    })
    .then(response => response.json())
    .then(data => {
      if (data.success) {
        this.updateAllDisplayValues()
        this.showAllDisplays()
        this.hideControlRow()
        this.isEditing = false
        this.removeEditingRowClass()
      } else {
        alert('Error updating transaction: ' + (data.errors || 'Unknown error'))
        this.resetAllValues()
      }
    })
    .catch(error => {
      console.error('Error:', error)
      alert('Error updating transaction. Please try again.')
      this.resetAllValues()
    })
  }

  // Collect data from all fields
  collectFieldData() {
    const data = {
      cleared: this.element.dataset.cleared === 'true',
      memo: this.element.dataset.memo || '',
      date: '',
      vendor: '',
      amount: '',
      lineId: this.element.dataset.lineId || '',
      ledgerId: this.element.dataset.ledgerId || '',
      subcategoryId: this.element.dataset.subcategoryId || ''
    }

    // Get values from input fields
    this.inputTargets.forEach(input => {
      const fieldName = input.dataset.fieldName
      if (fieldName) {
        data[fieldName] = input.value
      }
    })

    return data
  }

  // Update all display values
  updateAllDisplayValues() {
    this.inputTargets.forEach((input, index) => {
      const display = this.displayTargets[index]
      if (display) {
        const fieldName = input.dataset.fieldName
        if (fieldName === 'amount') {
          const formattedValue = new Intl.NumberFormat('en-US', {
            style: 'currency',
            currency: 'USD'
          }).format(parseFloat(input.value))
          display.textContent = formattedValue
          display.dataset.amount = (parseFloat(input.value) * 100).toString()
        } else {
          display.textContent = input.value
        }
      }
    })
  }

  // Remove editing row class
  removeEditingRowClass() {
    const row = this.element.closest('[data-trx-selection-target="row"]')
    if (row) {
      row.classList.remove('editing-row')
    }
  }
}
