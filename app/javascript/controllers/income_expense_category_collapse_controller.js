import { Controller } from "@hotwired/stimulus"

// Toggles visibility of subcategory and total rows for an expense category on the income/expense report.
// Attach to the category header <tr> with class "income-expense-category-header"; add a button
// with data-action="click->income-expense-category-collapse#toggle" and
// data-income-expense-category-collapse-target="chevron" for the icon.
export default class extends Controller {
  static targets = ["chevron", "toggleButton", "categoryTotal"]

  connect() {
    this.updateChevron()
    this.updateCategoryTotalsVisibility()
  }

  toggle(event) {
    event.preventDefault()
    event.stopPropagation()
    const stopClasses = ["income-expense-category-header", "expenses-section-header"]
    let row = this.element.nextElementSibling

    while (row) {
      if (stopClasses.some((c) => row.classList.contains(c))) break
      row.classList.toggle("hidden")
      row = row.nextElementSibling
    }

    this.element.classList.toggle("category-collapsed", this.isCollapsed())
    this.updateChevron()
    this.updateCategoryTotalsVisibility()
  }

  isCollapsed() {
    const stopClasses = ["income-expense-category-header", "expenses-section-header"]
    let row = this.element.nextElementSibling
    while (row) {
      if (stopClasses.some((c) => row.classList.contains(c))) break
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

  updateCategoryTotalsVisibility() {
    const collapsed = this.isCollapsed()
    this.categoryTotalTargets.forEach((el) => {
      el.classList.toggle("hidden", !collapsed)
    })
  }
}
