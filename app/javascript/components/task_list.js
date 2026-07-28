import { createApp } from "vue"

const FILTER_LABELS = {
  all: "All",
  today: "Due today",
  overdue: "Overdue",
  pending: "Pending",
  completed: "Completed"
}

// Owns the task list: filtering, sorting and pagination happen server-side, but
// this component drives them over fetch so search filters *as you type*
// (debounced) with no full page reload — the search box keeps focus.
const TaskList = {
  props: {
    initial: { type: Object, required: true },
    filters: { type: Array, required: true },
    csrf: { type: String, required: true }
  },
  data() {
    return {
      items: this.initial.tasks,
      counts: this.initial.counts,
      filter: this.initial.filter,
      query: this.initial.query,
      page: this.initial.page,
      totalPages: this.initial.total_pages,
      totalCount: this.initial.total_count,
      loading: false,
      searchTimer: null
    }
  },
  computed: {
    resultSummary() {
      const noun = this.totalCount === 1 ? "task" : "tasks"
      const base = `${this.totalCount} ${noun}`
      return this.query ? `${base} matching “${this.query}”` : base
    }
  },
  methods: {
    label(key) {
      return FILTER_LABELS[key] || key
    },
    // Fetch a page of results from the server for the current filter/query.
    async load({ page = 1 } = {}) {
      this.loading = true
      const url = `/tasks.json?filter=${encodeURIComponent(this.filter)}` +
        `&q=${encodeURIComponent(this.query)}&page=${page}`
      try {
        const response = await fetch(url, {
          headers: { Accept: "application/json" },
          credentials: "same-origin"
        })
        const data = await response.json()
        this.items = data.tasks
        this.counts = data.counts
        this.filter = data.filter
        this.page = data.page
        this.totalPages = data.total_pages
        this.totalCount = data.total_count
        this.syncUrl()
      } finally {
        this.loading = false
      }
    },
    // Keep the address bar in sync so refresh/bookmark/share works.
    syncUrl() {
      const params = new URLSearchParams()
      if (this.filter !== "all") params.set("filter", this.filter)
      if (this.query) params.set("q", this.query)
      if (this.page > 1) params.set("page", this.page)
      const qs = params.toString()
      window.history.replaceState({}, "", qs ? `/tasks?${qs}` : "/tasks")
    },
    onSearchInput() {
      // Debounce so we don't hit the server on every keystroke.
      clearTimeout(this.searchTimer)
      this.searchTimer = setTimeout(() => this.load({ page: 1 }), 250)
    },
    setFilter(key) {
      this.filter = key
      this.load({ page: 1 })
    },
    goToPage(page) {
      if (page < 1 || page > this.totalPages) return
      this.load({ page })
    },
    async request(url, method) {
      const response = await fetch(url, {
        method,
        headers: { "X-CSRF-Token": this.csrf, Accept: "application/json" },
        credentials: "same-origin"
      })
      if (!response.ok && response.status >= 400) {
        throw new Error(`Request failed: ${response.status}`)
      }
    },
    async toggle(task) {
      try {
        await this.request(`/tasks/${task.id}/toggle`, "PATCH")
        // Reload the current page so counts and filtered views stay accurate.
        await this.load({ page: this.page })
      } catch (e) {
        window.location.reload()
      }
    },
    async destroy(task) {
      if (!window.confirm(`Delete "${task.title}"?`)) return
      try {
        await this.request(`/tasks/${task.id}`, "DELETE")
        await this.load({ page: this.page })
      } catch (e) {
        window.location.reload()
      }
    }
  },
  template: `
    <div>
      <div class="toolbar">
        <nav class="filters">
          <button v-for="key in filters" :key="key"
                  type="button"
                  :class="{ active: filter === key }"
                  @click="setFilter(key)">
            {{ label(key) }} ({{ counts[key] }})
          </button>
        </nav>

        <div class="search-form">
          <input type="search" v-model="query" @input="onSearchInput"
                 placeholder="Search tasks…" class="search" aria-label="Search tasks">
        </div>
      </div>

      <p class="result-count">{{ resultSummary }}</p>

      <p v-if="items.length === 0" class="empty">No tasks match this view.</p>

      <ul v-else class="task-list" :class="{ loading }">
        <li v-for="task in items" :key="task.id"
            class="task" :class="{ completed: task.completed, overdue: task.overdue }">
          <label class="task-toggle" :class="{ done: task.completed }"
                 :title="task.completed ? 'Click to mark as not done' : 'Click to mark as done'">
            <input type="checkbox" :checked="task.completed" @change="toggle(task)">
            <span>{{ task.completed ? "Completed" : "Mark complete" }}</span>
          </label>
          <div class="task-body">
            <a :href="'/tasks/' + task.id" class="task-title">{{ task.title }}</a>
            <p class="task-meta">
              <span>Complete by {{ task.complete_by }}</span>
              <span v-if="task.overdue" class="badge-overdue">Overdue</span>
            </p>
          </div>
          <div class="task-actions">
            <a :href="'/tasks/' + task.id + '/edit'">Edit</a>
            <a :href="'/tasks/new?copy_from=' + task.id" class="link-action">Copy</a>
            <button type="button" class="link-danger" @click="destroy(task)">Delete</button>
          </div>
        </li>
      </ul>

      <nav v-if="totalPages > 1" class="pagination">
        <button type="button" @click="goToPage(page - 1)" :disabled="page <= 1">← Prev</button>
        <span class="page-info">Page {{ page }} of {{ totalPages }}</span>
        <button type="button" @click="goToPage(page + 1)" :disabled="page >= totalPages">Next →</button>
      </nav>
    </div>
  `
}

export function mountTaskList() {
  const el = document.getElementById("task-list-app")
  if (!el || el.dataset.mounted) return

  el.dataset.mounted = "true"
  createApp(TaskList, {
    initial: JSON.parse(el.dataset.initial),
    filters: JSON.parse(el.dataset.filters),
    csrf: el.dataset.csrf
  }).mount(el)
}
