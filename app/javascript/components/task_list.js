import { createApp } from "vue"

// Interactive task list: filter, search, mark complete/incomplete and delete
// without a full page reload. Actions call the standard Rails endpoints with a
// CSRF token, then update local state so the list stays in sync.
const TaskList = {
  props: {
    tasks: { type: Array, required: true },
    csrf: { type: String, required: true }
  },
  data() {
    return {
      items: this.tasks,
      filter: "all",
      query: ""
    }
  },
  computed: {
    counts() {
      return {
        all: this.items.length,
        pending: this.items.filter((t) => !t.completed).length,
        completed: this.items.filter((t) => t.completed).length,
        overdue: this.items.filter((t) => t.overdue).length
      }
    },
    visibleTasks() {
      const q = this.query.trim().toLowerCase()
      return this.items.filter((t) => {
        if (this.filter === "pending" && t.completed) return false
        if (this.filter === "completed" && !t.completed) return false
        if (this.filter === "overdue" && !t.overdue) return false
        if (q && !`${t.title} ${t.description}`.toLowerCase().includes(q)) return false
        return true
      })
    }
  },
  methods: {
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
        task.completed = !task.completed
        task.overdue = !task.completed && task.past
      } catch (e) {
        window.location.reload()
      }
    },
    async destroy(task) {
      if (!window.confirm(`Delete "${task.title}"?`)) return
      try {
        await this.request(`/tasks/${task.id}`, "DELETE")
        this.items = this.items.filter((t) => t.id !== task.id)
      } catch (e) {
        window.location.reload()
      }
    }
  },
  template: `
    <div>
      <div class="toolbar">
        <div class="filters">
          <button v-for="f in ['all', 'pending', 'overdue', 'completed']"
                  :key="f"
                  :class="{ active: filter === f }"
                  @click="filter = f">
            {{ f[0].toUpperCase() + f.slice(1) }} ({{ counts[f] }})
          </button>
        </div>
        <input type="search" v-model="query" placeholder="Search tasks…" class="search">
      </div>

      <p v-if="visibleTasks.length === 0" class="empty">No tasks match this view.</p>

      <ul class="task-list">
        <li v-for="task in visibleTasks" :key="task.id"
            class="task" :class="{ completed: task.completed, overdue: task.overdue }">
          <input type="checkbox" :checked="task.completed" @change="toggle(task)"
                 :aria-label="task.completed ? 'Mark as pending' : 'Mark as complete'">
          <div class="task-body">
            <a :href="'/tasks/' + task.id" class="task-title">{{ task.title }}</a>
            <p v-if="task.description" class="task-desc">{{ task.description }}</p>
            <p class="task-meta">
              <span>Complete by {{ task.complete_by }}</span>
              <span v-if="task.overdue" class="badge-overdue">Overdue</span>
              <span v-if="task.completed" class="badge-done">Done</span>
            </p>
          </div>
          <div class="task-actions">
            <a :href="'/tasks/' + task.id + '/edit'">Edit</a>
            <button type="button" class="link-danger" @click="destroy(task)">Delete</button>
          </div>
        </li>
      </ul>
    </div>
  `
}

export function mountTaskList() {
  const el = document.getElementById("task-list-app")
  if (!el || el.dataset.mounted) return

  el.dataset.mounted = "true"
  createApp(TaskList, {
    tasks: JSON.parse(el.dataset.tasks || "[]"),
    csrf: el.dataset.csrf
  }).mount(el)
}
