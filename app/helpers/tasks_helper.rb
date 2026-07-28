module TasksHelper
  # Serialize tasks for the Vue list component, with display-ready fields so the
  # client doesn't have to reimplement time-zone-aware formatting.
  def tasks_json(tasks)
    tasks.map do |task|
      {
        id: task.id,
        title: task.title,
        description: task.description.to_s,
        complete_by: task.complete_by.strftime("%b %-d, %Y at %I:%M %p"),
        completed: task.completed?,
        overdue: task.overdue?,
        past: task.complete_by.past?
      }
    end.to_json
  end

  # Value for an HTML datetime-local input.
  def datetime_local_value(time)
    time&.strftime("%Y-%m-%dT%H:%M")
  end
end
