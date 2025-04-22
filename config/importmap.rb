# Pin npm packages by running ./bin/importmap

pin "application", to: "application.js"

# Pin external libraries (via CDN)
pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
pin_all_from "app/javascript/controllers", under: "controllers"

# Pin local libraries
pin "chartkick", to: "https://ga.jspm.io/npm:chartkick@5.0.1/dist/chartkick.js"
pin "chart.js", to: "https://ga.jspm.io/npm:chart.js@4.4.9/dist/chart.js"
pin "chart.js/auto", to: "https://ga.jspm.io/npm:chart.js@4.4.9/auto/auto.js"
pin "@kurkle/color", to: "https://ga.jspm.io/npm:@kurkle/color@0.3.2/dist/color.esm.js"
