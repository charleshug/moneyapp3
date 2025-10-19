import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["field", "input", "display", "controlRow", "submitButton", "cancelButton"]
  static values = { 
    trxId: String,
    fieldName: String,
    originalValue: String
  }

  connect() {
    this.isEditing = false
    this.originalValue = this.originalValueValue
  }

  startEdit(event) {
    if (event) {
      event.preventDefault()
      event.stopPropagation()
    }
    
    if (this.isEditing) return
    
    this.isEditing = true
    this.showInput()
    this.focusInput()
  }

  // Handle single click to prevent row selection
  handleClick(event) {
    event.stopPropagation()
  }

  cancelEdit(event) {
    event.preventDefault()
    event.stopPropagation()
    
    this.isEditing = false
    this.resetValue()
    this.showDisplay()
    this.hideControlRow()
    this.removeEditingRowClass()
  }

  saveEdit(event) {
    event.preventDefault()
    event.stopPropagation()
    
    const newValue = this.inputTarget.value.trim()
    
    if (newValue === this.originalValue) {
      this.cancelEdit(event)
      return
    }
    
    this.updateTransaction(newValue)
  }

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

  showInput() {
    this.displayTarget.classList.add('hidden')
    this.inputTarget.classList.remove('hidden')
  }

  showDisplay() {
    this.displayTarget.classList.remove('hidden')
    this.inputTarget.classList.add('hidden')
  }

  showControlRow() {
    this.controlRowTarget.classList.remove('hidden')
  }

  hideControlRow() {
    this.controlRowTarget.classList.add('hidden')
  }

  focusInput() {
    setTimeout(() => {
      this.inputTarget.focus()
      this.inputTarget.select()
    }, 10)
  }

  resetValue() {
    this.inputTarget.value = this.originalValue
  }

  updateTransaction(newValue) {
    const formData = new FormData()
    formData.append('trx[cleared]', this.element.dataset.cleared === 'true')
    formData.append('trx[memo]', this.element.dataset.memo || '')
    
    // Update the specific field based on fieldName
    switch (this.fieldNameValue) {
      case 'amount':
        formData.append('trx[lines_attributes][0][amount]', (parseFloat(newValue) * 100).toString())
        // Add line attributes for amount field
        formData.append('trx[lines_attributes][0][id]', this.element.dataset.lineId || '')
        formData.append('trx[lines_attributes][0][ledger_id]', this.element.dataset.ledgerId || '')
        formData.append('trx[lines_attributes][0][subcategory_form_id]', this.element.dataset.subcategoryId || '')
        break
      case 'memo':
        formData.append('trx[memo]', newValue)
        break
      case 'date':
        formData.append('trx[date]', newValue)
        break
      case 'vendor':
        formData.append('trx[vendor_custom_text]', newValue)
        break
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
        this.originalValue = newValue
        this.updateDisplayValue(newValue)
        this.showDisplay()
        this.hideControlRow()
        this.isEditing = false
        this.removeEditingRowClass()
      } else {
        alert('Error updating transaction: ' + (data.errors || 'Unknown error'))
        this.resetValue()
      }
    })
    .catch(error => {
      console.error('Error:', error)
      alert('Error updating transaction. Please try again.')
      this.resetValue()
    })
  }

  updateDisplayValue(newValue) {
    if (this.fieldNameValue === 'amount') {
      const formattedValue = new Intl.NumberFormat('en-US', {
        style: 'currency',
        currency: 'USD'
      }).format(parseFloat(newValue))
      this.displayTarget.textContent = formattedValue
      this.displayTarget.dataset.amount = (parseFloat(newValue) * 100).toString()
    } else {
      this.displayTarget.textContent = newValue
    }
  }

  removeEditingRowClass() {
    const row = this.element.closest('[data-trx-selection-target="row"]')
    if (row) {
      row.classList.remove('editing-row')
    }
  }
}
