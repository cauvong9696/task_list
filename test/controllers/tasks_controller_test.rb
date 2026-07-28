require "test_helper"

class TasksControllerTest < ActionDispatch::IntegrationTest
  setup { @task = tasks(:pending_future) }

  test "index lists tasks" do
    get tasks_url
    assert_response :success
    assert_select "h1", "Tasks"
  end

  test "index sorts tasks ascending by complete_by" do
    get tasks_url
    # overdue: 2.days.ago, done: 1.day.from_now, pending_future: 3.days.from_now
    assert_equal [ tasks(:overdue).id, tasks(:done).id, tasks(:pending_future).id ],
                 rendered_task_ids
  end

  test "index marks overdue tasks in the payload" do
    get tasks_url
    entry = rendered_payload.find { |t| t["id"] == tasks(:overdue).id }
    assert entry["overdue"], "overdue task should be flagged"
  end

  test "today filter limits to tasks due by end of today (including overdue)" do
    due_today = Task.create!(title: "Due today", complete_by: Time.current.end_of_day - 1.hour)
    get tasks_url(filter: "today")
    ids = rendered_task_ids
    assert_includes ids, due_today.id
    assert_includes ids, tasks(:overdue).id
    assert_not_includes ids, tasks(:pending_future).id
  end

  test "overdue filter returns only overdue tasks" do
    get tasks_url(filter: "overdue")
    assert_equal [ tasks(:overdue).id ], rendered_task_ids
  end

  test "index paginates results" do
    15.times { |i| Task.create!(title: "Extra #{i}", complete_by: (i + 10).days.from_now) }
    get tasks_url
    assert_equal TasksController::PER_PAGE, rendered_task_ids.size
    assert_operator rendered_initial["total_pages"], :>, 1

    get tasks_url(page: 2)
    total = 3 + 15 # fixtures + created
    assert_equal total - TasksController::PER_PAGE, rendered_task_ids.size
  end

  test "search filters by title" do
    get tasks_url(q: "Renew")
    assert_equal [ tasks(:overdue).id ], rendered_task_ids
  end

  test "index responds to JSON for live search" do
    get tasks_url(format: :json, q: "Renew")
    assert_response :success
    body = response.parsed_body
    assert_equal [ tasks(:overdue).id ], body["tasks"].map { |t| t["id"] }
    assert_equal "Renew", body["query"]
    assert body["counts"].key?("today")
    assert body.key?("total_pages")
  end

  test "new renders the form mount point" do
    get new_task_url
    assert_response :success
    assert_select "#task-form-app"
  end

  test "creates a task with valid params" do
    assert_difference("Task.count", 1) do
      post tasks_url, params: { task: { title: "New task", description: "Details", complete_by: 2.days.from_now } }
    end
    assert_redirected_to task_url(Task.last)
  end

  test "does not create with a missing title" do
    assert_no_difference("Task.count") do
      post tasks_url, params: { task: { title: "", complete_by: 2.days.from_now } }
    end
    assert_response :unprocessable_entity
  end

  test "show renders a task" do
    get task_url(@task)
    assert_response :success
    assert_select "h1", @task.title
  end

  test "show redirects when task is missing" do
    get task_url(id: 0)
    assert_redirected_to tasks_url
  end

  test "updates a task" do
    patch task_url(@task), params: { task: { title: "Updated title" } }
    assert_redirected_to task_url(@task)
    assert_equal "Updated title", @task.reload.title
  end

  test "toggle marks a pending task complete and back" do
    assert_not @task.completed?
    patch toggle_task_url(@task)
    assert @task.reload.completed?
    patch toggle_task_url(@task)
    assert_not @task.reload.completed?
  end

  test "copy opens a prefilled new form without saving" do
    source = tasks(:done)
    assert_no_difference("Task.count") do
      get new_task_url(copy_from: source)
    end
    assert_response :success
    assert_select "#task-form-app[data-title=?]", "#{source.title} (copy)"
  end

  test "new ignores an unknown copy_from id" do
    get new_task_url(copy_from: 0)
    assert_response :success
    assert_select "#task-form-app[data-title='']"
  end

  test "destroys a task" do
    assert_difference("Task.count", -1) do
      delete task_url(@task)
    end
    assert_redirected_to tasks_url
  end

  private

  # The Vue list receives its initial state as JSON on the mount point.
  def rendered_initial
    node = css_select("#task-list-app").first
    JSON.parse(node["data-initial"])
  end

  def rendered_payload
    rendered_initial["tasks"]
  end

  def rendered_task_ids
    rendered_payload.map { |t| t["id"] }
  end
end
