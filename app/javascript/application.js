// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "chartkick"
import "controllers"

import Chart from "chart.js/auto"
// Assign to global so Chartkick can see it
window.Chart = Chart