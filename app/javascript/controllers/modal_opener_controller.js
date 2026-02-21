// Stores click position so the modal can open at that spot (e.g. overspending settings)
import { Controller } from "@hotwired/stimulus"

const STORAGE_KEY = "modalOpenPosition"

export default class extends Controller {
  storePosition(event) {
    sessionStorage.setItem(STORAGE_KEY, `${event.clientX},${event.clientY}`)
  }
}
