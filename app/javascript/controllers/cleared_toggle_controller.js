import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["circle"]
  static values = {
    trxId: Number,
    cleared: Boolean
  }

  toggle(event) {
    event.stopPropagation()
    
    fetch(`/trxes/${this.trxIdValue}/toggle_cleared`, {
      method: 'POST',
      headers: {
        'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content,
        'Accept': 'application/json'
      }
    })
    .then(response => {
      if (!response.ok) {
        return response.json().then(data => {
          throw new Error(data.error || 'Failed to update transaction')
        })
      }
      return response.json()
    })
    .then(data => {
      this.clearedValue = data.cleared
      this.updateCircle()
    })
    .catch(error => {
      console.error(error)
      // Optionally show a toast notification here
    })
  }

  updateCircle() {
    this.circleTarget.classList.toggle('bg-green-500')
    this.circleTarget.classList.toggle('bg-gray-300')
  }
} 