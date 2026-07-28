require "test_helper"

class TasksControllerTest < ActionDispatch::IntegrationTest
  setup { @task = tasks(:pending_future) }

  test "index lists tasks" do
    get tasks_url
    assert_response :success
    assert_select "h1", "Tasks"
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
end
