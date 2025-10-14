import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["form", "button"]

  showForm() {
    this.formTarget.classList.remove('hidden')
    this.buttonTarget.disabled = true
    this.buttonTarget.textContent = 'New Transaction (Form Open)'
  }

  hideForm() {
    this.formTarget.classList.add('hidden')
    this.buttonTarget.disabled = false
    this.buttonTarget.innerHTML = '<i class="fas fa-plus mr-2"></i> New Transaction'
  }
}
