import { createApp } from "vue"

// A Vue-enhanced task form used for both creating and editing a task.
// It progressively enhances a plain Rails form: real HTTP submission is still
// a standard POST/PATCH, so it works with CSRF and server-side validation,
// while Vue adds live validation and a preview.
const TaskForm = {
  props: {
    url: { type: String, required: true },
    method: { type: String, default: "post" },
    csrf: { type: String, required: true },
    submitLabel: { type: String, default: "Save task" },
    initialTitle: { type: String, default: "" },
    initialDescription: { type: String, default: "" },
    initialCompleteBy: { type: String, default: "" }
  },
  data() {
    return {
      title: this.initialTitle,
      description: this.initialDescription,
      completeBy: this.initialCompleteBy,
      touched: false
    }
  },
  computed: {
    titleError() {
      return this.title.trim() === "" ? "Title is required." : null
    },
    completeByError() {
      return this.completeBy === "" ? "A complete-by date & time is required." : null
    },
    valid() {
      return !this.titleError && !this.completeByError
    }
  },
  methods: {
    onSubmit(event) {
      this.touched = true
      if (!this.valid) event.preventDefault()
    }
  },
  template: `
    <form :action="url" method="post" novalidate @submit="onSubmit" class="card">
      <input type="hidden" name="authenticity_token" :value="csrf">
      <input v-if="method !== 'post'" type="hidden" name="_method" :value="method">

      <div class="field">
        <label for="task_title">Title *</label>
        <input id="task_title" name="task[title]" type="text" v-model="title" autocomplete="off">
        <p v-if="touched && titleError" class="error">{{ titleError }}</p>
      </div>

      <div class="field">
        <label for="task_description">Description</label>
        <textarea id="task_description" name="task[description]" rows="4" v-model="description"></textarea>
      </div>

      <div class="field">
        <label for="task_complete_by">Complete by *</label>
        <input id="task_complete_by" name="task[complete_by]" type="datetime-local" v-model="completeBy">
        <p v-if="touched && completeByError" class="error">{{ completeByError }}</p>
      </div>

      <div class="actions">
        <button type="submit" :disabled="!valid">{{ submitLabel }}</button>
        <a href="/tasks">Cancel</a>
      </div>

      <div class="preview">
        <strong>Live preview</strong>
        <h2>{{ title.trim() || "(untitled)" }}</h2>
        <p><strong>Description:</strong> {{ description.trim() || "(no description)" }}</p>
        <p><strong>Complete by:</strong> {{ completeBy || "(not set)" }}</p>
      </div>
    </form>
  `
}

export function mountTaskForm() {
  const el = document.getElementById("task-form-app")
  if (!el || el.dataset.mounted) return

  el.dataset.mounted = "true"
  createApp(TaskForm, {
    url: el.dataset.url,
    method: el.dataset.method || "post",
    csrf: el.dataset.csrf,
    submitLabel: el.dataset.submitLabel,
    initialTitle: el.dataset.title,
    initialDescription: el.dataset.description,
    initialCompleteBy: el.dataset.completeBy
  }).mount(el)
}
