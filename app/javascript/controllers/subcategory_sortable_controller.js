import { Controller } from "@hotwired/stimulus"

// Drag-and-drop reorder for subcategory rows on the budgets table.
// Attach to the tbody; subcategory rows must have data-subcategory-id and data-category-id.
// The drag handle (e.g. hamburger) must have data-subcategory-sortable-target="handle".
export default class extends Controller {
  static values = { reorderUrl: String }
  static targets = ["handle"]

  connect() {
    this.rows = this.element.querySelectorAll("tr[data-subcategory-id][data-category-id]")
    this.rows.forEach((row) => this.setupRow(row))
  }

  setupRow(row) {
    const handle = row.querySelector("[data-subcategory-sortable-target='handle']")
    if (!handle) return

    handle.draggable = true
    handle.setAttribute("aria-label", "Drag to reorder subcategory")
    handle.addEventListener("dragstart", this.dragstart.bind(this))
    row.addEventListener("dragover", this.dragover.bind(this))
    row.addEventListener("drop", this.drop.bind(this))
    row.addEventListener("dragleave", this.dragleave.bind(this))
    handle.addEventListener("dragend", this.dragend.bind(this))
  }

  dragstart(e) {
    const row = e.target.closest("tr")
    if (!row) return
    this.draggedRow = row
    this.draggedCategoryId = row.dataset.categoryId
    e.dataTransfer.effectAllowed = "move"
    e.dataTransfer.setData("text/plain", row.dataset.subcategoryId)
    e.dataTransfer.setData("application/json", JSON.stringify({
      subcategory_id: row.dataset.subcategoryId,
      category_id: row.dataset.categoryId
    }))
    row.classList.add("opacity-50", "bg-blue-50")
  }

  dragover(e) {
    const row = e.target.closest("tr")
    if (!row || !row.dataset.subcategoryId || row.dataset.categoryId !== this.draggedCategoryId) return
    if (row === this.draggedRow) return
    e.preventDefault()
    e.dataTransfer.dropEffect = "move"
    this.clearDropIndicator()
    row.classList.add("subcategory-drop-indicator")
  }

  dragleave(e) {
    const row = e.target.closest("tr")
    if (row && row.dataset.subcategoryId) row.classList.remove("subcategory-drop-indicator")
  }

  drop(e) {
    e.preventDefault()
    const row = e.target.closest("tr")
    if (!row || !row.dataset.subcategoryId || row.dataset.categoryId !== this.draggedCategoryId) return
    if (row === this.draggedRow) return
    this.clearDropIndicator()

    const categoryRows = Array.from(this.element.querySelectorAll(`tr[data-category-id="${this.draggedCategoryId}"][data-subcategory-id]`))
    const targetIndex = categoryRows.indexOf(row)
    const position = targetIndex + 1

    this.reorder(this.draggedRow.dataset.subcategoryId, position)
  }

  dragend(e) {
    if (this.draggedRow) {
      this.draggedRow.classList.remove("opacity-50", "bg-blue-50")
      this.draggedRow = null
    }
    this.clearDropIndicator()
  }

  clearDropIndicator() {
    this.element.querySelectorAll(".subcategory-drop-indicator").forEach((el) => el.classList.remove("subcategory-drop-indicator"))
  }

  async reorder(subcategoryId, position) {
    const csrfToken = document.querySelector("meta[name='csrf-token']")?.content
    const formData = new FormData()
    formData.append("subcategory_id", subcategoryId)
    formData.append("position", position)
    formData.append("authenticity_token", csrfToken)

    const response = await fetch(this.reorderUrlValue, {
      method: "POST",
      body: formData,
      headers: {
        "Accept": "text/vnd.turbo-stream.html",
        "X-Requested-With": "XMLHttpRequest"
      }
    })

    if (!response.ok) return
    const body = await response.text()
    if (body) Turbo.renderStreamMessage(body)
  }
}
