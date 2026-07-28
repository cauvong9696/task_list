module TasksHelper
  # Display-ready fields for a single task so the Vue client doesn't have to
  # reimplement time-zone-aware formatting.
  def task_payload(task)
    {
      id: task.id,
      title: task.title,
      description: task.description.to_s,
      complete_by: task.complete_by.strftime("%b %-d, %Y at %I:%M %p"),
      completed: task.completed?,
      overdue: task.overdue?,
      past: task.complete_by.past?
    }
  end

  # Serialize a collection of tasks for the Vue list component.
  def tasks_json(tasks)
    tasks.map { |task| task_payload(task) }.to_json
  end

  # Value for an HTML datetime-local input.
  def datetime_local_value(time)
    time&.strftime("%Y-%m-%dT%H:%M")
  end

  # Build a tasks_path preserving the current query params with overrides.
  # Pass a nil value to drop a param (e.g. page: nil resets pagination).
  def tasks_url_with(overrides)
    params = request.query_parameters.symbolize_keys.merge(overrides)
    tasks_path(params.compact)
  end

  FILTER_LABELS = {
    "all" => "All",
    "today" => "Due today",
    "overdue" => "Overdue",
    "pending" => "Pending",
    "completed" => "Completed"
  }.freeze

  def filter_label(key)
    FILTER_LABELS.fetch(key, key.to_s.titleize)
  end
end
