import { Controller } from "@hotwired/stimulus"

// Toggles visibility of subcategory rows for a parent category on the budgets table.
// Attach to the parent category <tr>; add a button with data-action="click->category-collapse#toggle"
// and data-category-collapse-target="chevron" containing the chevron icon.
export default class extends Controller {
  static targets = ["chevron", "toggleButton"]

  connect() {
    this.updateChevron()
  }

  toggle(event) {
    event.preventDefault()
    event.stopPropagation()
    const categoryId = this.element.dataset.categoryId
    if (!categoryId) return

    const parentRowClass = "category-parent-row"
    let row = this.element.nextElementSibling

    while (row) {
      if (row.classList.contains(parentRowClass)) break
      if (row.dataset.categoryId === categoryId) {
        row.classList.toggle("hidden")
      }
      row = row.nextElementSibling
    }

    this.element.classList.toggle("category-collapsed", this.isCollapsed())
    this.updateChevron()
  }

  isCollapsed() {
    const categoryId = this.element.dataset.categoryId
    if (!categoryId) return false
    let row = this.element.nextElementSibling
    const parentRowClass = "category-parent-row"
    while (row) {
      if (row.classList.contains(parentRowClass)) break
      if (row.dataset.categoryId === categoryId) {
        return row.classList.contains("hidden")
      }
      row = row.nextElementSibling
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
