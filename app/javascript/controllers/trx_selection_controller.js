import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["checkbox", "row", "headerCheckbox", "balanceContainer", "amount"]
  static values = { 
    trxId: String,
    selected: Boolean
  }

  connect() {
    console.log('trx-selection controller connected')
    this.selectedTrxes = new Set()
    this.lastSelectedIndex = null
    this.editingRow = null
    
    // Add global click listener for click-outside functionality (using capture phase)
    this.boundHandleGlobalClick = this.handleGlobalClick.bind(this)
    document.addEventListener('click', this.boundHandleGlobalClick, true)
    
    // Add global keydown listener for escape key functionality
    this.boundHandleGlobalKeydown = this.handleGlobalKeydown.bind(this)
    document.addEventListener('keydown', this.boundHandleGlobalKeydown)
  }

  disconnect() {
    // Remove global listeners when controller disconnects
    document.removeEventListener('click', this.boundHandleGlobalClick)
    document.removeEventListener('keydown', this.boundHandleGlobalKeydown)
  }

  // Handle checkbox click
  toggleSelection(event) {
    event.stopPropagation()
    const trxId = event.target.dataset.trxId
    const row = event.target.closest('[data-trx-selection-target="row"]')
    const index = Array.from(this.rowTargets).indexOf(row)
    
    // For checkbox clicks, always add to existing selections (don't clear others)
    this.selectTrx(trxId, index, true, event.shiftKey) // Force ctrl-like behavior
  }

  // Handle row click
  selectRow(event) {
    console.log('selectRow called')
    // Don't trigger if clicking on checkbox (handled by toggleSelection)
    if (event.target.type === 'checkbox') return
    
    const row = event.currentTarget
    const trxId = row.dataset.trxId
    const index = Array.from(this.rowTargets).indexOf(row)
    
    // Respect Ctrl and Shift keys for multi-selection
    const isCtrlClick = event.ctrlKey || event.metaKey // Support both Ctrl and Cmd (Mac)
    const isShiftClick = event.shiftKey
    
    this.selectTrx(trxId, index, isCtrlClick, isShiftClick)
  }

  // Handle row double-click
  activateRowEditing(event) {
    console.log('activateRowEditing called from dblclick')
    const row = event.currentTarget
    const trxId = row.dataset.trxId
    console.log('trxId:', trxId)
    
    // Cancel any existing editing row first
    if (this.editingRow && this.editingRow !== row) {
      console.log('Canceling existing editing row:', this.editingRow.dataset.trxId)
      this.cancelRowEditing(this.editingRow)
    }
    
    // Set this as the currently editing row
    this.editingRow = row
    console.log('Set new editing row:', trxId)
    
    // Store the current display HTML before replacing with edit form
    const frame = document.getElementById(`trx_${trxId}`)
    console.log('frame:', frame)
    if (frame) {
      frame.dataset.originalHtml = frame.innerHTML
      console.log('Stored original HTML, length:', frame.dataset.originalHtml.length)
    }
    
    // Load edit form into the turbo frame
    fetch(`/trxes/${trxId}/edit_row`, {
      method: 'GET',
      headers: {
        'Accept': 'text/vnd.turbo-stream.html',
        'X-Requested-With': 'XMLHttpRequest'
      }
    })
    .then(response => {
      if (response.ok) {
        return response.text()
      }
      throw new Error('Network response was not ok')
    })
    .then(html => {
      // Process the turbo stream response
      Turbo.renderStreamMessage(html)
    })
    .catch(error => {
      console.error('Error loading edit form:', error)
    })
  }


  // Handle submit button click (no longer needed - handled by turbo frames)
  handleSubmit(event) {
    // This method is no longer needed as form submission is handled by turbo frames
  }

  // Handle cancel button click (no longer needed - handled by turbo frames)
  handleCancel(event) {
    // This method is no longer needed as cancel is handled by turbo frames
  }

  // Handle keyboard events in input fields (no longer needed - handled by turbo frames)
  handleKeydown(event) {
    // This method is no longer needed as keyboard handling is done by the trx-row-edit controller
  }

  // Handle global clicks to cancel editing when clicking outside
  handleGlobalClick(event) {
    // Only proceed if there's an editing row
    if (!this.editingRow) return
    
    // Check if the click is inside the editing row
    const clickedInsideEditingRow = this.editingRow.contains(event.target)
    
    // If click is outside the editing row, cancel editing
    if (!clickedInsideEditingRow) {
      // Cancel the editing first
      this.cancelRowEditing(this.editingRow)
      
      // Stop the event from propagating to other handlers
      // This prevents other click handlers (like cleared toggle) from executing
      event.stopPropagation()
      event.preventDefault()
    }
  }

  // Handle global keydown events (primarily for escape key)
  handleGlobalKeydown(event) {
    // Only handle escape key when there's an editing row
    if (event.key === 'Escape' && this.editingRow) {
      event.preventDefault()
      event.stopPropagation()
      this.cancelRowEditing(this.editingRow)
    }
  }

  // Update category display when subcategory changes
  updateCategory(event) {
    const subcategorySelect = event.target
    const selectedOption = subcategorySelect.options[subcategorySelect.selectedIndex]
    const categoryName = selectedOption.dataset.categoryName || ''
    
    // Find the category display field in the same row
    const row = subcategorySelect.closest('[data-trx-selection-target="row"]')
    const categoryDisplay = row.querySelector('[data-field-name="category_display"]')
    
    if (categoryDisplay) {
      categoryDisplay.textContent = categoryName
    }
  }

  // Save changes for a row (no longer needed - handled by turbo frames)
  saveRowChanges(row) {
    // This method is no longer needed as form submission is handled by turbo frames
  }

  // Cancel editing for a row
  cancelRowEditing(row) {
    const trxId = row.dataset.trxId
    
    // Restore the original HTML from memory
    const frame = document.getElementById(`trx_${trxId}`)
    if (frame && frame.dataset.originalHtml) {
      frame.innerHTML = frame.dataset.originalHtml
      // Clear the stored HTML
      delete frame.dataset.originalHtml
    }
    
    // Clear the editing row reference
    if (this.editingRow === row) {
      console.log('Clearing editing row reference')
      this.editingRow = null
    }
  }

  // Update display values after successful save (no longer needed - handled by turbo frames)
  updateRowDisplayValues(row, fieldData) {
    // This method is no longer needed as display updates are handled by turbo frames
  }

  // Main selection logic
  selectTrx(trxId, index, isCtrlClick, isShiftClick) {
    if (isShiftClick && this.lastSelectedIndex !== null) {
      // Range selection
      const start = Math.min(this.lastSelectedIndex, index)
      const end = Math.max(this.lastSelectedIndex, index)
      
      for (let i = start; i <= end; i++) {
        const row = this.rowTargets[i]
        const id = row.dataset.trxId
        this.selectedTrxes.add(id)
        this.updateRowSelection(row, true)
      }
    } else if (isCtrlClick) {
      // Toggle individual selection (checkbox clicks or ctrl+click)
      if (this.selectedTrxes.has(trxId)) {
        this.selectedTrxes.delete(trxId)
        this.updateRowSelection(this.rowTargets[index], false)
      } else {
        this.selectedTrxes.add(trxId)
        this.updateRowSelection(this.rowTargets[index], true)
      }
    } else {
      // Single selection (row clicks without ctrl) - clear others
      this.clearAllSelections()
      this.selectedTrxes.add(trxId)
      this.updateRowSelection(this.rowTargets[index], true)
    }
    
    this.lastSelectedIndex = index
    this.updateHeaderCheckbox()
    this.updateBalanceDisplay()
  }

  // Handle header checkbox (select all/none)
  toggleAll(event) {
    event.stopPropagation()
    
    if (this.selectedTrxes.size === this.rowTargets.length) {
      // Deselect all
      this.clearAllSelections()
    } else {
      // Select all
      this.rowTargets.forEach((row, index) => {
        const trxId = row.dataset.trxId
        this.selectedTrxes.add(trxId)
        this.updateRowSelection(row, true)
      })
      this.lastSelectedIndex = this.rowTargets.length - 1
    }
    
    this.updateHeaderCheckbox()
    this.updateBalanceDisplay()
  }

  // Clear all selections
  clearAllSelections() {
    this.selectedTrxes.clear()
    this.rowTargets.forEach(row => {
      this.updateRowSelection(row, false)
    })
    this.lastSelectedIndex = null
  }

  // Update visual state of a row
  updateRowSelection(row, isSelected) {
    const checkbox = row.querySelector('[data-trx-selection-target="checkbox"]')
    if (checkbox) {
      checkbox.checked = isSelected
    }
    
    if (isSelected) {
      row.classList.add('bg-yellow-200')
      row.classList.remove('odd:bg-white', 'even:bg-blue-50', 'hover:bg-gray-50')
      // Add a more specific class to override hover
      row.classList.add('selected-row')
    } else {
      row.classList.remove('bg-yellow-200', 'selected-row')
      // Restore original alternating colors and hover
      const index = Array.from(this.rowTargets).indexOf(row)
      if (index % 2 === 0) {
        row.classList.add('odd:bg-white')
      } else {
        row.classList.add('even:bg-blue-50')
      }
      row.classList.add('hover:bg-gray-50')
    }
  }

  // Update header checkbox state
  updateHeaderCheckbox() {
    if (this.selectedTrxes.size === 0) {
      this.headerCheckboxTarget.checked = false
      this.headerCheckboxTarget.indeterminate = false
    } else if (this.selectedTrxes.size === this.rowTargets.length) {
      this.headerCheckboxTarget.checked = true
      this.headerCheckboxTarget.indeterminate = false
    } else {
      this.headerCheckboxTarget.checked = false
      this.headerCheckboxTarget.indeterminate = true
    }
  }

  // Update balance display based on selection
  updateBalanceDisplay() {
    if (this.selectedTrxes.size >= 2) {
      // Show selection balance display only when 2 or more transactions are selected
      this.showSelectionBalanceDisplay()
    } else {
      // Show normal balance display
      this.showNormalBalanceDisplay()
    }
  }

  // Show selection balance display with client-side calculation
  showSelectionBalanceDisplay() {
    const selectedIds = Array.from(this.selectedTrxes)
    
    // Calculate total amount of selected transactions
    let totalAmount = 0
    let selectedCount = 0
    
    this.rowTargets.forEach((row, index) => {
      const trxId = row.dataset.trxId
      if (selectedIds.includes(trxId)) {
        const amountElement = row.querySelector('[data-trx-selection-target="amount"]')
        if (amountElement) {
          const amount = parseInt(amountElement.dataset.amount) || 0
          totalAmount += amount
          selectedCount++
        }
      }
    })
    
    // Format the amount for display
    const formattedAmount = this.formatCurrency(totalAmount / 100.0)
    
    // Update the balance display
    this.balanceContainerTarget.innerHTML = `
      <div class="bg-gray-50 border border-gray-200 rounded-lg p-4 min-w-80">
        <div class="flex items-center justify-between">
          <!-- Selected Total -->
          <div class="text-center border-r border-gray-300 pr-6">
            <div class="text-sm font-medium text-gray-600 mb-1">Selected Total (${selectedCount})</div>
            <div class="text-lg font-bold text-yellow-600">
              ${formattedAmount}
            </div>
          </div>
          
          <!-- Working Balance -->
          <div class="text-center">
            <div class="text-sm font-medium text-gray-600 mb-1">Working Balance</div>
            <div class="text-lg font-bold text-blue-600">
              ${this.calculateWorkingBalance()}
            </div>
          </div>
        </div>
      </div>
    `
  }

  // Show normal balance display
  showNormalBalanceDisplay() {
    // Reload the original balance display
    this.balanceContainerTarget.innerHTML = `
      <div class="bg-gray-50 border border-gray-200 rounded-lg p-4 min-w-80">
        <div class="flex items-center justify-between">
          <!-- Cleared Balance -->
          <div class="text-center">
            <div class="text-sm font-medium text-gray-600 mb-1">Cleared Balance</div>
            <div class="text-lg font-bold text-green-600" data-balance="cleared">
              ${this.calculateClearedBalance()}
            </div>
          </div>
          
          <!-- Plus Sign -->
          <div class="text-2xl font-bold text-gray-400 mx-4">+</div>
          
          <!-- Uncleared Transactions -->
          <div class="text-center">
            <div class="text-sm font-medium text-gray-600 mb-1">Uncleared Transactions</div>
            <div class="text-lg font-bold text-orange-600" data-balance="uncleared">
              ${this.calculateUnclearedBalance()}
            </div>
          </div>
          
          <!-- Equals Sign -->
          <div class="text-2xl font-bold text-gray-400 mx-4">=</div>
          
          <!-- Working Balance -->
          <div class="text-center">
            <div class="text-sm font-medium text-gray-600 mb-1">Working Balance</div>
            <div class="text-lg font-bold text-blue-600" data-balance="working">
              ${this.calculateWorkingBalance()}
            </div>
          </div>
        </div>
      </div>
    `
  }

  // Helper methods for calculations
  formatCurrency(amount) {
    return new Intl.NumberFormat('en-US', {
      style: 'currency',
      currency: 'USD'
    }).format(amount)
  }

  calculateWorkingBalance() {
    let total = 0
    this.amountTargets.forEach(amountElement => {
      const amount = parseInt(amountElement.dataset.amount) || 0
      total += amount
    })
    return this.formatCurrency(total / 100.0)
  }

  calculateClearedBalance() {
    let total = 0
    this.rowTargets.forEach(row => {
      const clearedButton = row.querySelector('[data-cleared-toggle-target="circle"]')
      if (clearedButton && clearedButton.classList.contains('bg-green-500')) {
        const amountElement = row.querySelector('[data-trx-selection-target="amount"]')
        if (amountElement) {
          const amount = parseInt(amountElement.dataset.amount) || 0
          total += amount
        }
      }
    })
    return this.formatCurrency(total / 100.0)
  }

  calculateUnclearedBalance() {
    let total = 0
    this.rowTargets.forEach(row => {
      const clearedButton = row.querySelector('[data-cleared-toggle-target="circle"]')
      if (clearedButton && clearedButton.classList.contains('bg-gray-300')) {
        const amountElement = row.querySelector('[data-trx-selection-target="amount"]')
        if (amountElement) {
          const amount = parseInt(amountElement.dataset.amount) || 0
          total += amount
        }
      }
    })
    return this.formatCurrency(total / 100.0)
  }

}