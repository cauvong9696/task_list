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
end
