import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["cell", "input"]
  static values = { 
    subcategoryId: Number,
    ledgerId: Number,
    date: String,
    currentBudget: Number,
    monthIndex: Number
  }

  connect() {
    this.originalValue = this.currentBudgetValue
  }

  startEdit(event) {
    event.preventDefault()
    
    // Create input element
    const input = document.createElement("input")
    input.type = "number"
    input.step = "0.01"
    input.value = this.currentBudgetValue
    input.className = "w-full text-right border-0 bg-transparent focus:outline-none focus:ring-2 focus:ring-blue-500"
    
    // Replace cell content with input
    this.cellTarget.innerHTML = ""
    this.cellTarget.appendChild(input)
    
    // Focus and select the input
    input.focus()
    input.select()
    
    // Add event listeners
    input.addEventListener("blur", this.finishEdit.bind(this))
    input.addEventListener("keydown", this.handleKeydown.bind(this))
  }

  handleKeydown(event) {
    if (event.key === "Enter") {
      event.preventDefault()
      this.finishEdit(event)
    } else if (event.key === "Escape") {
      event.preventDefault()
      this.cancelEdit()
    }
  }

  finishEdit(event) {
    const input = event.target
    const newValue = parseFloat(input.value) || 0
    
    // Don't update if value hasn't changed
    if (newValue === this.originalValue) {
      this.cancelEdit()
      return
    }

    this.updateBudget(newValue)
  }

  cancelEdit() {
    this.cellTarget.innerHTML = this.formatCurrency(this.originalValue)
  }

  async updateBudget(amount) {
    const url = this.ledgerIdValue ? 
      `/ledgers/${this.ledgerIdValue}/update_budget` : 
      "/ledgers/create_budget"
    
    const params = {
      budget: amount,
      subcategory_id: this.subcategoryIdValue,
      date: this.dateValue
    }

    try {
      const method = this.ledgerIdValue ? "PATCH" : "POST"
      const response = await fetch(url, {
        method: method,
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": document.querySelector("[name='csrf-token']").content
        },
        body: JSON.stringify(params)
      })

      const data = await response.json()

      if (data.success) {
        // Update the cell with new formatted value
        this.cellTarget.innerHTML = data.budget
        
        // Update the balance cell if it exists
        this.updateBalanceCell(data.balance)
        
        // Update budget summary section if present (budgets index page)
        if (data.summary) {
          this.updateBudgetSummary(data.summary)
        }
        // Update category row and table totals (budgets index page)
        if (data.category || data.totals) {
          this.updateBudgetTable(data.category, data.totals)
        }
        
        // Update the original value and the value used when re-opening the editor
        this.originalValue = amount
        this.currentBudgetValue = amount

        // Update ledger ID if this was a new ledger
        if (data.ledger_id) {
          this.ledgerIdValue = data.ledger_id
        }

        // Refresh all visible month columns (summaries, balances, totals) via Turbo Stream
        if (data.turbo_stream) {
          Turbo.renderStreamMessage(data.turbo_stream)
        }
      } else {
        // Show error and revert
        this.showError(data.errors?.join(", ") || "Failed to update budget")
        this.cancelEdit()
      }
    } catch (error) {
      console.error("Error updating budget:", error)
      this.showError("Network error occurred")
      this.cancelEdit()
    }
  }

  updateBalanceCell(balance) {
    const row = this.cellTarget.closest("tr")
    const monthIndex = String(this.monthIndexValue ?? 0)
    const monthCells = row.querySelectorAll(`td[data-month-index="${monthIndex}"]`)
    const balanceCell = monthCells.length >= 1 ? monthCells[monthCells.length - 1] : null
    if (balanceCell) {
      balanceCell.innerHTML = balance
    }
  }

  updateBudgetSummary(summary) {
    const monthIndex = String(this.monthIndexValue ?? 0)
    const table = this.cellTarget.closest("table")
    const summaryTd = table?.querySelector(`td[data-month-index="${monthIndex}"][colspan="3"]`) ?? null
    if (!summaryTd) return
    const budgetedLine = summaryTd.querySelector('[data-summary-line="budgeted"]')
    const availableLine = summaryTd.querySelector('[data-summary-line="available"]')
    if (budgetedLine) {
      const amountSpan = budgetedLine.querySelector("span:first-child")
      if (amountSpan) {
        amountSpan.textContent = summary.budget_current
        amountSpan.classList.toggle("text-red-600", summary.budget_current_negative)
      }
    }
    if (availableLine) {
      const amountDiv = availableLine.querySelector("div:first-child")
      if (amountDiv) {
        amountDiv.textContent = summary.budget_available_current
        amountDiv.classList.toggle("text-red-600", summary.budget_available_negative)
      }
    }
  }

  updateBudgetTable(category, totals) {
    const monthIndex = String(this.monthIndexValue ?? 0)
    const table = this.cellTarget.closest("table")
    if (!table) return
    if (category) {
      const categoryRow = table.querySelector(`tr[data-category-id="${category.id}"]`)
      if (categoryRow) {
        const budgetCell = categoryRow.querySelector(`td[data-month-index="${monthIndex}"][data-category-type="budget"]`)
        const balanceCell = categoryRow.querySelector(`td[data-month-index="${monthIndex}"][data-category-type="balance"]`)
        if (budgetCell) budgetCell.innerHTML = `<strong>${category.budget}</strong>`
        if (balanceCell) {
          const balanceClass = category.balance_negative ? "text-red-600" : ""
          balanceCell.innerHTML = `<strong class="${balanceClass}">${category.balance}</strong>`
        }
      }
    }
    if (totals) {
      const totalsRow = table.querySelector("tr[data-budget-totals-row]")
      if (totalsRow) {
        const budgetEl = totalsRow.querySelector(`td[data-month-index="${monthIndex}"][data-total-type="budget"]`)
        const actualEl = totalsRow.querySelector(`td[data-month-index="${monthIndex}"][data-total-type="actual"]`)
        const balanceEl = totalsRow.querySelector(`td[data-month-index="${monthIndex}"][data-total-type="balance"]`)
        if (budgetEl) budgetEl.innerHTML = `<strong>${totals.budget}</strong>`
        if (actualEl) actualEl.innerHTML = `<strong>${totals.actual}</strong>`
        if (balanceEl) {
          balanceEl.innerHTML = `<strong>${totals.balance}</strong>`
          balanceEl.classList.toggle("text-red-600", totals.balance_negative)
        }
      }
    }
  }

  showError(message) {
    // Create a temporary error message
    const errorDiv = document.createElement("div")
    errorDiv.className = "text-red-500 text-sm"
    errorDiv.textContent = message
    
    this.cellTarget.innerHTML = ""
    this.cellTarget.appendChild(errorDiv)
    
    // Revert after 3 seconds
    setTimeout(() => {
      this.cancelEdit()
    }, 3000)
  }

  formatCurrency(amount) {
    return new Intl.NumberFormat('en-US', {
      style: 'currency',
      currency: 'USD'
    }).format(amount)
  }
}
