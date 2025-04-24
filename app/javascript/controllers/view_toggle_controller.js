import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["chartView", "tableView", "icon"]

  connect() {
    // Chart view is shown by default
    this.showChart()
  }

  toggle() {
    if (this.chartViewTarget.classList.contains('hidden')) {
      this.showChart()
    } else {
      this.showTable()
    }
  }

  showChart() {
    this.chartViewTarget.classList.remove('hidden')
    this.tableViewTarget.classList.add('hidden')
    this.iconTarget.classList.remove('fa-chart-pie')
    this.iconTarget.classList.add('fa-table')
  }

  showTable() {
    this.chartViewTarget.classList.add('hidden')
    this.tableViewTarget.classList.remove('hidden')
    this.iconTarget.classList.remove('fa-table')
    this.iconTarget.classList.add('fa-chart-pie')
  }
} 