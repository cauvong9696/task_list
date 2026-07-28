# Pin npm packages by running ./bin/importmap

pin "application"
pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
pin_all_from "app/javascript/controllers", under: "controllers"

# Vue 3 (ESM browser build, includes the template compiler) vendored in
# vendor/javascript. No Node build step required.
pin "vue", to: "vue.js"
pin_all_from "app/javascript/components", under: "components"
