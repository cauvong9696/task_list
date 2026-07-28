// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "controllers"
import { mountTaskForm } from "components/task_form"
import { mountTaskList } from "components/task_list"

document.addEventListener("turbo:load", () => {
  mountTaskForm()
  mountTaskList()
})
