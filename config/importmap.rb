# Pin npm packages by running ./bin/importmap

pin "application", to: "application.js"

# Pin external libraries (via CDN)
pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
pin_all_from "app/javascript/controllers", under: "controllers"

pin "chart.js", to: "https://cdn.jsdelivr.net/npm/chart.js@4.4.9/+esm"
