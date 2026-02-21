import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["cell", "input"]
  static values = { 
    subcategoryId: Number,
    ledgerId: Number,
    date: String,
    currentBudget: Number
  }

  connect() {
    this.originalValue = this.currentBudgetValue
  }

  startEdit(event) {
    event.preventDefault()
    
    // Create input element (use originalValue so re-opening the form shows last saved value)
    // type="text" so user can enter relative expressions like "+ 0.5" or "- 5"
    const input = document.createElement("input")
    input.type = "text"
    input.inputMode = "decimal"
    input.placeholder = "e.g. 10 or + 0.5"
    input.value = this.originalValue
    input.className = "w-full text-right border-0 bg-transparent focus:outline-none focus:ring-2 focus:ring-blue-500"
    
    // Replace cell content with input
    this.cellTarget.innerHTML = ""
    this.cellTarget.appendChild(input)
    
    // Focus and select the input (setTimeout so select runs after focus; then typing replaces content)
    input.focus()
    setTimeout(() => input.select(), 0)
    
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
    const newValue = this.parseBudgetInput(input.value.trim(), this.originalValue)

    // Don't update if value hasn't changed
    if (newValue === this.originalValue) {
      this.cancelEdit()
      return
    }

    this.updateBudget(newValue)
  }

  // Parses user input: supports relative ("+ 0.5"), expressions ("10 + 0.5"), or plain number
  parseBudgetInput(raw, baseValue) {
    if (raw === "") return baseValue
    const round = (n) => Math.round(n * 100) / 100

    // Relative only: "+ 0.5", "- 5" → apply to current value (works when user replaced content)
    const relativeMatch = raw.match(/^\s*([+\-*\/])\s*([\d.]+)\s*$/)
    if (relativeMatch) {
      const op = relativeMatch[1]
      const num = parseFloat(relativeMatch[2])
      if (Number.isNaN(num)) return baseValue
      switch (op) {
        case "+": return round(baseValue + num)
        case "-": return round(baseValue - num)
        case "*": return round(baseValue * num)
        case "/": return num !== 0 ? round(baseValue / num) : baseValue
        default: return baseValue
      }
    }

    // Expression: "10 + 0.5", "10+0.5" → compute (handles when user appended to existing value)
    const exprMatch = raw.match(/^\s*([\d.]+)\s*([+\-*\/])\s*([\d.]+)\s*$/)
    if (exprMatch) {
      const a = parseFloat(exprMatch[1])
      const op = exprMatch[2]
      const b = parseFloat(exprMatch[3])
      if (Number.isNaN(a) || Number.isNaN(b)) return baseValue
      switch (op) {
        case "+": return round(a + b)
        case "-": return round(a - b)
        case "*": return round(a * b)
        case "/": return b !== 0 ? round(a / b) : baseValue
        default: return baseValue
      }
    }

    // Plain number: "10", "0.5" → absolute value
    const absolute = parseFloat(raw)
    return Number.isNaN(absolute) ? baseValue : round(absolute)
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
        
        // Update the original value
        this.originalValue = amount
        
        // Update ledger ID if this was a new ledger
        if (data.ledger_id) {
          this.ledgerIdValue = data.ledger_id
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
    // Find the balance cell in the same row
    const row = this.cellTarget.closest("tr")
    const balanceCell = row.querySelector("td:last-child")
    if (balanceCell) {
      balanceCell.innerHTML = balance
    }
  }

  updateBudgetSummary(summary) {
    const budgetedEl = document.getElementById("budget-summary-budgeted")
    const availableEl = document.getElementById("budget-summary-available")
    if (budgetedEl) {
      budgetedEl.textContent = summary.budget_current
      budgetedEl.classList.toggle("text-red-600", summary.budget_current_negative)
    }
    if (availableEl) {
      availableEl.textContent = summary.budget_available_current
      availableEl.classList.toggle("text-red-600", summary.budget_available_negative)
    }
  }

  updateBudgetTable(category, totals) {
    if (category) {
      const budgetEl = document.getElementById(`budget-category-${category.id}-budget`)
      const balanceEl = document.getElementById(`budget-category-${category.id}-balance`)
      if (budgetEl) {
        budgetEl.innerHTML = `<strong>${category.budget}</strong>`
      }
      if (balanceEl) {
        const balanceClass = category.balance_negative ? "text-red-600" : ""
        balanceEl.innerHTML = `<strong class="${balanceClass}">${category.balance}</strong>`
      }
    }
    if (totals) {
      const budgetEl = document.getElementById("budget-table-total-budget")
      const actualEl = document.getElementById("budget-table-total-actual")
      const balanceEl = document.getElementById("budget-table-total-balance")
      if (budgetEl) budgetEl.innerHTML = `<strong>${totals.budget}</strong>`
      if (actualEl) actualEl.innerHTML = `<strong>${totals.actual}</strong>`
      if (balanceEl) {
        balanceEl.innerHTML = `<strong>${totals.balance}</strong>`
        balanceEl.classList.toggle("text-red-600", totals.balance_negative)
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
