import { Controller } from "@hotwired/stimulus"

// Expand or collapse all category rows in the budget table.
// Attach to the table element; buttons use data-action="click->category-collapse-all#expandAll" etc.
export default class extends Controller {
  static values = {
    tbodySelector: { type: String, default: "#budget-table-tbody" }
  }

  expandAll() {
    this.setAllExpanded(true)
  }

  collapseAll() {
    this.setAllExpanded(false)
  }

  setAllExpanded(expanded) {
    const tbody = this.element.querySelector(this.tbodySelectorValue)
    if (!tbody) return

    const parentRows = tbody.querySelectorAll(".category-parent-row")
    const parentRowClass = "category-parent-row"

    parentRows.forEach((parentRow) => {
      const categoryId = parentRow.dataset.categoryId
      if (!categoryId) return

      let row = parentRow.nextElementSibling
      while (row) {
        if (row.classList.contains(parentRowClass)) break
        if (row.dataset.categoryId === categoryId) {
          if (expanded) {
            row.classList.remove("hidden")
          } else {
            row.classList.add("hidden")
          }
        }
        row = row.nextElementSibling
      }

      const chevron = parentRow.querySelector("[data-category-collapse-target='chevron']")
      if (chevron) {
        chevron.classList.toggle("fa-chevron-down", expanded)
        chevron.classList.toggle("fa-chevron-right", !expanded)
      }
      const toggleBtn = parentRow.querySelector("[data-category-collapse-target='toggleButton']")
      if (toggleBtn) {
        toggleBtn.setAttribute("aria-expanded", expanded)
      }
      parentRow.classList.toggle("category-collapsed", !expanded)
    })
  }
}
