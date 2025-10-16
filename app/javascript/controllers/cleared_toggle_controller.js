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
      this.refreshBalanceSection()
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

  refreshBalanceSection() {
    // Get current filter parameters from the URL
    const currentParams = new URLSearchParams(window.location.search)
    
    // Pass all current URL parameters to maintain the same filtering
    fetch(`/trxes/balance_info?${currentParams.toString()}`, {
      method: 'GET',
      headers: {
        'Accept': 'application/json'
      }
    })
    .then(response => {
      if (!response.ok) {
        throw new Error('Failed to fetch balance information')
      }
      return response.json()
    })
    .then(data => {
      this.updateBalanceDisplay(data)
    })
    .catch(error => {
      console.error('Error refreshing balance section:', error)
    })
  }

  getBudgetId() {
    // Try to get budget ID from various sources
    const budgetIdElement = document.querySelector('[data-budget-id]')
    if (budgetIdElement) {
      return budgetIdElement.dataset.budgetId
    }
    
    // Fallback: extract from URL if needed
    const urlParams = new URLSearchParams(window.location.search)
    return urlParams.get('budget_id') || '1' // Default fallback
  }

  updateBalanceDisplay(data) {
    // Update cleared balance
    const clearedBalanceElement = document.querySelector('[data-balance="cleared"]')
    if (clearedBalanceElement) {
      clearedBalanceElement.textContent = data.cleared_balance
    }
    
    // Update cleared count
    const clearedCountElement = document.querySelector('[data-count="cleared"]')
    if (clearedCountElement) {
      clearedCountElement.textContent = data.cleared_count
    }
    
    // Update uncleared balance
    const unclearedBalanceElement = document.querySelector('[data-balance="uncleared"]')
    if (unclearedBalanceElement) {
      unclearedBalanceElement.textContent = data.uncleared_balance
    }
    
    // Update uncleared count
    const unclearedCountElement = document.querySelector('[data-count="uncleared"]')
    if (unclearedCountElement) {
      unclearedCountElement.textContent = data.uncleared_count
    }
    
    // Update working balance
    const workingBalanceElement = document.querySelector('[data-balance="working"]')
    if (workingBalanceElement) {
      workingBalanceElement.textContent = data.working_balance
    }
    
    // Update total count
    const totalCountElement = document.querySelector('[data-count="total"]')
    if (totalCountElement) {
      totalCountElement.textContent = data.total_count
    }
  }
} 