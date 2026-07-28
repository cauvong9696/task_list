import { createApp } from "vue"

// A Vue-enhanced task form used for both creating and editing a task.
// It progressively enhances a plain Rails form: real HTTP submission is still
// a standard multipart POST/PATCH, so it works with CSRF, file uploads and
// server-side validation. The description field is a Mattermost-style Markdown
// editor with a formatting toolbar and a Write/Preview toggle.
const TaskForm = {
  props: {
    url: { type: String, required: true },
    method: { type: String, default: "post" },
    csrf: { type: String, required: true },
    submitLabel: { type: String, default: "Save task" },
    cancelUrl: { type: String, default: "/tasks" },
    initialTitle: { type: String, default: "" },
    initialDescription: { type: String, default: "" },
    initialCompleteBy: { type: String, default: "" },
    initialFiles: { type: Array, default: () => [] }
  },
  data() {
    return {
      title: this.initialTitle,
      description: this.initialDescription,
      completeBy: this.initialCompleteBy,
      existingFiles: this.initialFiles.slice(),
      removeIds: [],
      selectedNames: [],
      touched: false,
      mode: "write",
      previewHtml: "",
      previewLoading: false,
      previewTimer: null
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
    },
    onFilesChange(event) {
      this.selectedNames = Array.from(event.target.files).map((f) => f.name)
    },

    // --- Write / Preview toggle ---
    setMode(mode) {
      this.mode = mode
      if (mode === "preview") this.refreshPreview()
    },
    onDescriptionInput() {
      clearTimeout(this.previewTimer)
      this.previewTimer = setTimeout(() => this.refreshPreview(), 250)
    },
    // Server-rendered + sanitized, so the preview matches the saved result and
    // the returned HTML is safe to inject.
    async refreshPreview() {
      if (this.description.trim() === "") {
        this.previewHtml = ""
        return
      }
      this.previewLoading = true
      try {
        const response = await fetch("/markdown_preview", {
          method: "POST",
          headers: {
            "Content-Type": "application/json",
            "X-CSRF-Token": this.csrf,
            Accept: "application/json"
          },
          credentials: "same-origin",
          body: JSON.stringify({ text: this.description })
        })
        const data = await response.json()
        this.previewHtml = data.html
      } catch (e) {
        // Keep the previous preview if the request fails.
      } finally {
        this.previewLoading = false
      }
    },

    // --- Formatting toolbar ---
    // Wrap the current selection with `before`/`after` markers.
    surround(before, after) {
      const ta = this.$refs.editor
      const start = ta.selectionStart
      const end = ta.selectionEnd
      const text = this.description
      const selected = text.slice(start, end)
      this.description = text.slice(0, start) + before + selected + after + text.slice(end)
      this.$nextTick(() => {
        ta.focus()
        const from = start + before.length
        ta.setSelectionRange(from, from + selected.length)
      })
      this.onDescriptionInput()
    },
    // Prefix each line touched by the selection (lists, quote, heading).
    prefixLines(makePrefix) {
      const ta = this.$refs.editor
      const start = ta.selectionStart
      const end = ta.selectionEnd
      const text = this.description
      const lineStart = text.lastIndexOf("\n", start - 1) + 1
      const block = text.slice(lineStart, end)
      const replaced = block
        .split("\n")
        .map((line, i) => makePrefix(i) + line)
        .join("\n")
      this.description = text.slice(0, lineStart) + replaced + text.slice(end)
      this.$nextTick(() => {
        ta.focus()
        ta.setSelectionRange(lineStart, lineStart + replaced.length)
      })
      this.onDescriptionInput()
    },
    bold() { this.surround("**", "**") },
    italic() { this.surround("*", "*") },
    strike() { this.surround("~~", "~~") },
    codeInline() { this.surround("`", "`") },
    codeBlock() { this.surround("```\n", "\n```") },
    link() { this.surround("[", "](https://)") },
    heading() { this.prefixLines(() => "### ") },
    quote() { this.prefixLines(() => "> ") },
    bulletList() { this.prefixLines(() => "- ") },
    numberList() { this.prefixLines((i) => `${i + 1}. `) }
  },
  template: `
    <form :action="url" method="post" enctype="multipart/form-data" novalidate @submit="onSubmit" class="card">
      <input type="hidden" name="authenticity_token" :value="csrf">
      <input v-if="method !== 'post'" type="hidden" name="_method" :value="method">

      <div class="field">
        <label for="task_title">Title *</label>
        <input id="task_title" name="task[title]" type="text" v-model="title" autocomplete="off">
        <p v-if="touched && titleError" class="error">{{ titleError }}</p>
      </div>

      <div class="field">
        <label for="task_description">Description <span class="hint">(Markdown supported)</span></label>

        <div class="md-editor">
          <div class="md-tabs">
            <button type="button" :class="{ active: mode === 'write' }" @click="setMode('write')">Write</button>
            <button type="button" :class="{ active: mode === 'preview' }" @click="setMode('preview')">Preview</button>
          </div>

          <div class="md-toolbar" v-show="mode === 'write'">
            <button type="button" title="Bold" @click="bold"><strong>B</strong></button>
            <button type="button" title="Italic" @click="italic"><em>I</em></button>
            <button type="button" title="Strikethrough" @click="strike"><s>S</s></button>
            <span class="md-sep"></span>
            <button type="button" title="Heading" @click="heading">H</button>
            <button type="button" title="Quote" @click="quote">&#8220;</button>
            <button type="button" title="Bulleted list" @click="bulletList">&bull;</button>
            <button type="button" title="Numbered list" @click="numberList">1.</button>
            <span class="md-sep"></span>
            <button type="button" title="Link" @click="link">&#128279;</button>
            <button type="button" title="Inline code" @click="codeInline">&lt;/&gt;</button>
            <button type="button" title="Code block" @click="codeBlock">{ }</button>
          </div>

          <textarea id="task_description" name="task[description]" rows="6" ref="editor"
                    v-show="mode === 'write'" v-model="description" @input="onDescriptionInput"
                    placeholder="Write a description using Markdown…"></textarea>

          <div class="md-preview-pane" v-show="mode === 'preview'">
            <p v-if="previewLoading" class="muted">Rendering…</p>
            <div v-else-if="previewHtml" class="markdown-body" v-html="previewHtml"></div>
            <p v-else class="muted">Nothing to preview.</p>
          </div>
        </div>

        <details class="md-help">
          <summary>Formatting help</summary>
          <ul>
            <li><code>**bold**</code>, <code>*italic*</code>, <code>~~strike~~</code></li>
            <li><code># Heading</code>, <code>&gt; quote</code></li>
            <li><code>- bullet</code> or <code>1. numbered</code> list</li>
            <li><code>[link text](https://example.com)</code></li>
            <li><code>&#96;inline code&#96;</code> and fenced code blocks</li>
          </ul>
        </details>
      </div>

      <div class="field">
        <label for="task_complete_by">Complete by *</label>
        <input id="task_complete_by" name="task[complete_by]" type="datetime-local" v-model="completeBy">
        <p v-if="touched && completeByError" class="error">{{ completeByError }}</p>
      </div>

      <div class="field">
        <label for="task_supporting_files">Supporting files</label>
        <input id="task_supporting_files" name="task[supporting_files][]" type="file" multiple
               @change="onFilesChange">
        <ul v-if="selectedNames.length" class="file-hints">
          <li v-for="name in selectedNames" :key="name">{{ name }}</li>
        </ul>
      </div>

      <div v-if="existingFiles.length" class="field">
        <label>Attached files</label>
        <ul class="attachment-list">
          <li v-for="file in existingFiles" :key="file.id">
            <label class="attachment-remove">
              <input type="checkbox" name="task[remove_file_ids][]" :value="file.id" v-model="removeIds">
              Remove
            </label>
            <a :href="file.url" target="_blank" rel="noopener">{{ file.name }}</a>
            <span class="attachment-size">({{ file.size }})</span>
          </li>
        </ul>
      </div>

      <div class="actions">
        <button type="submit" :disabled="!valid">{{ submitLabel }}</button>
        <a :href="cancelUrl">Cancel</a>
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
    cancelUrl: el.dataset.cancelUrl || "/tasks",
    initialTitle: el.dataset.title,
    initialDescription: el.dataset.description,
    initialCompleteBy: el.dataset.completeBy,
    initialFiles: JSON.parse(el.dataset.files || "[]")
  }).mount(el)
}
