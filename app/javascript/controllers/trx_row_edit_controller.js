import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["form"]
  static values = { trxId: String }
  
  connect() {
    // Focus the first input field when the edit form loads
    setTimeout(() => {
      const firstInput = this.element.querySelector('input, select, textarea')
      if (firstInput) {
        firstInput.focus()
        if (firstInput.type === 'text' || firstInput.type === 'number') {
          firstInput.select()
        }
      }
    }, 10)
  }
  
  handleSubmit(event) {
    // Form will submit normally via Turbo
    // The update.turbo_stream.erb will handle the response
  }
  
  cancel(event) {
    console.log('cancel called')
    event.preventDefault()
    
    // Get the trx ID
    const trxId = this.trxIdValue
    console.log('trxId:', trxId)
    
    // Restore the original HTML from memory
    const frame = document.getElementById(`trx_${trxId}`)
    console.log('frame:', frame)
    console.log('originalHtml exists:', !!frame?.dataset.originalHtml)
    if (frame && frame.dataset.originalHtml) {
      frame.innerHTML = frame.dataset.originalHtml
      console.log('Restored original HTML')
      // Clear the stored HTML
      delete frame.dataset.originalHtml
    } else {
      console.log('No original HTML found to restore')
    }
  }
  
  handleKeydown(event) {
    if (event.key === 'Escape') {
      event.preventDefault()
      this.cancel(event)
    }
  }
}