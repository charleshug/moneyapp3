import { Controller } from "@hotwired/stimulus"

// Toggles visibility of income source (vendor) rows for "All Income Sources" on the income/expense report.
// Stops at the row with class "expenses-section-header".
export default class extends Controller {
  static targets = ["chevron", "toggleButton", "categoryTotal"]

  connect() {
    this.updateChevron()
    this.updateCategoryTotalsVisibility()
  }

  toggle(event) {
    event.preventDefault()
    event.stopPropagation()
    const stopClass = "expenses-section-header"
    let row = this.element.nextElementSibling

    while (row) {
      if (row.classList.contains(stopClass)) break
      row.classList.toggle("hidden")
      row = row.nextElementSibling
    }

    this.element.classList.toggle("category-collapsed", this.isCollapsed())
    this.updateChevron()
    this.updateCategoryTotalsVisibility()
  }

  isCollapsed() {
    const stopClass = "expenses-section-header"
    let row = this.element.nextElementSibling
    while (row) {
      if (row.classList.contains(stopClass)) break
      return row.classList.contains("hidden")
    }
    return true
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
    if (!this.hasCategoryTotalTarget) return
    const collapsed = this.isCollapsed()
    this.categoryTotalTargets.forEach((el) => {
      el.classList.toggle("hidden", !collapsed)
    })
  }
}
