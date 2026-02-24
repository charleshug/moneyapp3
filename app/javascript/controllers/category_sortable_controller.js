import { Controller } from "@hotwired/stimulus"

// Drag-and-drop reorder for parent category rows on the budgets table.
// Attach to the tbody; parent rows must have data-category-id and must NOT have data-subcategory-id.
// The drag handle must have data-category-sortable-target="handle".
export default class extends Controller {
  static values = { reorderUrl: String }
  static targets = ["handle"]

  connect() {
    if (!this.reorderUrlValue) return
    this.parentRows = this.element.querySelectorAll("tr[data-category-id]:not([data-subcategory-id])")
    this.parentRows.forEach((row) => this.setupRow(row))
  }

  setupRow(row) {
    const handle = row.querySelector("[data-category-sortable-target='handle']")
    if (!handle) return

    handle.draggable = true
    handle.setAttribute("aria-label", "Drag to reorder categories")
    handle.addEventListener("dragstart", this.dragstart.bind(this))
    row.addEventListener("dragover", this.dragover.bind(this))
    row.addEventListener("drop", this.drop.bind(this))
    row.addEventListener("dragleave", this.dragleave.bind(this))
    handle.addEventListener("dragend", this.dragend.bind(this))
  }

  dragstart(e) {
    const row = e.target.closest("tr")
    if (!row || row.dataset.subcategoryId) return
    this.draggedRow = row
    e.dataTransfer.effectAllowed = "move"
    e.dataTransfer.setData("text/plain", row.dataset.categoryId)
    e.dataTransfer.setData("application/json", JSON.stringify({ category_id: row.dataset.categoryId }))
    row.classList.add("opacity-50", "bg-blue-50")
  }

  dragover(e) {
    const row = e.target.closest("tr")
    if (!row || row.dataset.subcategoryId || !row.dataset.categoryId) return
    if (row === this.draggedRow) return
    e.preventDefault()
    e.dataTransfer.dropEffect = "move"
    this.clearDropIndicator()
    row.classList.add("category-drop-indicator")
  }

  dragleave(e) {
    const row = e.target.closest("tr")
    if (row && row.dataset.categoryId && !row.dataset.subcategoryId) row.classList.remove("category-drop-indicator")
  }

  drop(e) {
    e.preventDefault()
    const row = e.target.closest("tr")
    if (!row || row.dataset.subcategoryId || !row.dataset.categoryId) return
    if (row === this.draggedRow) return
    this.clearDropIndicator()

    const parentRows = Array.from(this.element.querySelectorAll("tr[data-category-id]:not([data-subcategory-id])"))
    const position = parentRows.indexOf(row) + 1

    this.reorder(this.draggedRow.dataset.categoryId, position)
  }

  dragend(e) {
    if (this.draggedRow) {
      this.draggedRow.classList.remove("opacity-50", "bg-blue-50")
      this.draggedRow = null
    }
    this.clearDropIndicator()
  }

  clearDropIndicator() {
    this.element.querySelectorAll(".category-drop-indicator").forEach((el) => el.classList.remove("category-drop-indicator"))
  }

  async reorder(categoryId, position) {
    if (!this.reorderUrlValue) return
    const csrfToken = document.querySelector("meta[name='csrf-token']")?.content
    const formData = new FormData()
    formData.append("category_id", categoryId)
    formData.append("position", position)
    formData.append("authenticity_token", csrfToken)

    const response = await fetch(this.reorderUrlValue, {
      method: "POST",
      body: formData,
      headers: {
        "Accept": "text/vnd.turbo-stream.html",
        "X-Requested-With": "XMLHttpRequest",
        "X-CSRF-Token": csrfToken ?? ""
      }
    })

    if (!response.ok) return
    const body = await response.text()
    if (body) Turbo.renderStreamMessage(body)
  }
}
