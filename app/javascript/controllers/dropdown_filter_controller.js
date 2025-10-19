import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["button", "dropdown", "options", "selectedCount", "searchInput"]
  static values = { 
    fieldName: String,
    selectedIds: Array,
    placeholder: String
  }

  connect() {
    this.updateButtonText()
    this.initializeSelectedState()
    this.setupClickOutside()
    this.setupFormSubmission()
    this.setupSearch()
  }

  disconnect() {
    this.removeClickOutside()
  }

  setupSearch() {
    if (this.hasSearchInputTarget) {
      this.searchInputTarget.addEventListener('input', (event) => {
        this.filterOptions(event.target.value)
      })
      
      // Prevent search input clicks from closing dropdown
      this.searchInputTarget.addEventListener('click', (event) => {
        event.stopPropagation()
      })
    }
  }

  filterOptions(searchTerm) {
    const options = this.optionsTarget.querySelectorAll('.dropdown-filter-option')
    const searchLower = searchTerm.toLowerCase()
    
    options.forEach(option => {
      const label = option.querySelector('label')
      const text = label ? label.textContent.toLowerCase() : ''
      const isVisible = text.includes(searchLower)
      
      option.style.display = isVisible ? 'flex' : 'none'
    })
  }

  initializeSelectedState() {
    // Set the selected state for options that are already checked
    this.optionsTarget.querySelectorAll('input[type="checkbox"]').forEach(input => {
      if (input.checked) {
        const option = input.closest('.dropdown-filter-option')
        if (option) {
          option.classList.add('selected')
        }
      }
    })
  }

  toggle() {
    this.dropdownTarget.classList.toggle('hidden')
    if (!this.dropdownTarget.classList.contains('hidden')) {
      this.buttonTarget.classList.add('ring-2', 'ring-blue-500')
      // Clear search and show all options when opening
      if (this.hasSearchInputTarget) {
        this.searchInputTarget.value = ''
        this.filterOptions('')
      }
      // Focus the search input
      if (this.hasSearchInputTarget) {
        setTimeout(() => this.searchInputTarget.focus(), 100)
      }
    } else {
      this.buttonTarget.classList.remove('ring-2', 'ring-blue-500')
    }
  }

  selectOption(event) {
    const option = event.currentTarget
    const input = option.querySelector('input')
    const isChecked = input.checked
    
    // Check if this is a single-select field (like cleared_eq)
    const isSingleSelect = this.fieldNameValue.includes('_eq')
    
    if (isSingleSelect) {
      // For single-select fields, uncheck all other options first
      this.optionsTarget.querySelectorAll('input[type="checkbox"]').forEach(checkbox => {
        checkbox.checked = false
        checkbox.closest('.dropdown-filter-option').classList.remove('selected')
      })
      
      // Then check the selected option
      input.checked = !isChecked
      if (!isChecked) {
        this.selectedIdsValue = [input.value]
        option.classList.add('selected')
      } else {
        this.selectedIdsValue = []
        option.classList.remove('selected')
      }
    } else {
      // Multi-select behavior (for account_id_in, vendor_id_in, etc.)
      if (isChecked) {
        // Remove from selected
        this.selectedIdsValue = this.selectedIdsValue.filter(id => id !== input.value)
        option.classList.remove('selected')
      } else {
        // Add to selected
        this.selectedIdsValue = [...this.selectedIdsValue, input.value]
        option.classList.add('selected')
      }
      
      input.checked = !isChecked
    }
    
    this.updateButtonText()
    this.updateFormField()
  }

  updateButtonText() {
    const count = this.selectedIdsValue.length
    const isSingleSelect = this.fieldNameValue.includes('_eq')
    
    if (count === 0) {
      this.buttonTarget.textContent = this.placeholderValue
    } else if (count === 1) {
      const selectedOption = this.optionsTarget.querySelector(`input[value="${this.selectedIdsValue[0]}"]`)
      if (selectedOption) {
        const label = selectedOption.closest('div').querySelector('label').textContent.trim()
        this.buttonTarget.textContent = label
      }
    } else {
      // This should only happen for multi-select fields
      if (isSingleSelect) {
        // For single-select, show the selected option name
        const selectedOption = this.optionsTarget.querySelector(`input[value="${this.selectedIdsValue[0]}"]`)
        if (selectedOption) {
          const label = selectedOption.closest('div').querySelector('label').textContent.trim()
          this.buttonTarget.textContent = label
        }
      } else {
        this.buttonTarget.textContent = `(${count}) ${this.fieldNameValue.replace('_id_in', '').replace('_', ' ')} selected`
      }
    }
  }

  setupFormSubmission() {
    const form = this.element.closest('form')
    if (form && !form.hasAttribute('data-dropdown-form-setup')) {
      form.setAttribute('data-dropdown-form-setup', 'true')
      form.addEventListener('submit', (event) => {
        this.updateAllDropdownFields()
      })
    }
  }

  updateAllDropdownFields() {
    // Find all dropdown filter controllers and update their form fields
    const allDropdowns = document.querySelectorAll('[data-controller*="dropdown-filter"]')
    allDropdowns.forEach(dropdown => {
      const controller = this.application.getControllerForElementAndIdentifier(dropdown, 'dropdown-filter')
      if (controller) {
        controller.updateFormFieldOnly()
      }
    })
  }

  updateFormField() {
    // Update this dropdown's form fields
    this.updateFormFieldOnly()
    
    // Trigger form submission to apply filters
    const form = this.element.closest('form')
    if (form) {
      form.requestSubmit()
    }
  }

  updateFormFieldOnly() {
    // Find the container for hidden form fields
    const container = this.element.querySelector('.hidden-form-fields')
    if (container) {
      // Clear existing fields for this specific filter (both _eq and _in versions)
      const baseFieldName = this.fieldNameValue.replace('_in', '').replace('_eq', '')
      const existingFields = container.querySelectorAll(`input[name*="${baseFieldName}"]`)
      existingFields.forEach(field => field.remove())
      
      // Add new fields for each selected value
      this.selectedIdsValue.forEach(id => {
        const newField = document.createElement('input')
        newField.type = 'hidden'
        const isSingleSelect = this.fieldNameValue.includes('_eq')
        newField.name = isSingleSelect ? `q[${this.fieldNameValue}]` : `q[${this.fieldNameValue}][]`
        newField.value = id
        container.appendChild(newField)
      })
    }
  }

  setupClickOutside() {
    this.handleClickOutside = (event) => {
      if (!this.element.contains(event.target)) {
        this.dropdownTarget.classList.add('hidden')
        this.buttonTarget.classList.remove('ring-2', 'ring-blue-500')
      }
    }
    document.addEventListener('click', this.handleClickOutside)
  }

  removeClickOutside() {
    if (this.handleClickOutside) {
      document.removeEventListener('click', this.handleClickOutside)
    }
  }
}
