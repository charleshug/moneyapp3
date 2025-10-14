import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["container"]

  open() {
    this.element.classList.remove("hidden")
  }

  close() {
    this.element.classList.add("hidden")
  }
}
