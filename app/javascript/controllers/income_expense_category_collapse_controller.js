import { Controller } from "@hotwired/stimulus"

// Toggles visibility of subcategory and total rows for an expense category on the income/expense report.
// Attach to the category header <tr> with class "income-expense-category-header"; add a button
// with data-action="click->income-expense-category-collapse#toggle" and
// data-income-expense-category-collapse-target="chevron" for the icon.
export default class extends Controller {
  static targets = ["chevron", "toggleButton"]

  connect() {
    this.updateChevron()
  }

  toggle(event) {
    event.preventDefault()
    event.stopPropagation()
    const headerClass = "income-expense-category-header"
    let row = this.element.nextElementSibling

    while (row) {
      if (row.classList.contains(headerClass)) break
      row.classList.toggle("hidden")
      row = row.nextElementSibling
    }

    this.element.classList.toggle("category-collapsed", this.isCollapsed())
    this.updateChevron()
  }

  isCollapsed() {
    const headerClass = "income-expense-category-header"
    let row = this.element.nextElementSibling
    while (row) {
      if (row.classList.contains(headerClass)) break
      return row.classList.contains("hidden")
    }
    return false
  }

  updateChevron() {
    const collapsed = this.isCollapsed()
    if (this.hasChevronTarget) {
      this.chevronTarget.classList.toggle("fa-chevron-down", !collapsed)
      this.chevronTarget.classList.toggle("fa-chevron-right", collapsed)
    }
    if (this.hasToggleButtonTarget) {
      this.toggleButtonTarget.setAttribute("aria-expanded", !collapsed)
    }
  }
}
