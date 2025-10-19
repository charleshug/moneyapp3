import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["button", "dropdown", "options", "selectedCount"]
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
  }

  disconnect() {
    this.removeClickOutside()
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
    } else {
      this.buttonTarget.classList.remove('ring-2', 'ring-blue-500')
    }
  }

  selectOption(event) {
    const option = event.currentTarget
    const input = option.querySelector('input')
    const isChecked = input.checked
    
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
    this.updateButtonText()
    this.updateFormField()
  }

  updateButtonText() {
    const count = this.selectedIdsValue.length
    if (count === 0) {
      this.buttonTarget.textContent = this.placeholderValue
    } else if (count === 1) {
      const selectedOption = this.optionsTarget.querySelector(`input[value="${this.selectedIdsValue[0]}"]`)
      if (selectedOption) {
        const label = selectedOption.closest('div').querySelector('label').textContent.trim()
        this.buttonTarget.textContent = label
      }
    } else {
      this.buttonTarget.textContent = `(${count}) ${this.fieldNameValue} selected`
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
      // Clear existing fields for this specific filter
      const existingFields = container.querySelectorAll(`input[name*="${this.fieldNameValue}"]`)
      existingFields.forEach(field => field.remove())
      
      // Add new fields for each selected value
      this.selectedIdsValue.forEach(id => {
        const newField = document.createElement('input')
        newField.type = 'hidden'
        newField.name = `q[${this.fieldNameValue}][]`
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
