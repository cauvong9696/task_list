require "test_helper"

class TasksControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:alice)
    sign_in_as(@user)
    @task = tasks(:pending_future)
  end

  test "index requires authentication" do
    reset_session_for_test
    get tasks_url
    assert_redirected_to login_url
  end

  test "index only shows the current user's tasks" do
    get tasks_url
    assert_includes rendered_task_ids, tasks(:pending_future).id
    assert_not_includes rendered_task_ids, tasks(:bob_task).id
  end

  test "cannot access another user's task" do
    get task_url(tasks(:bob_task))
    assert_redirected_to tasks_url
  end

  test "admin sees every user's tasks" do
    sign_in_as(users(:admin))
    get tasks_url
    ids = rendered_task_ids
    assert_includes ids, tasks(:pending_future).id # alice's
    assert_includes ids, tasks(:bob_task).id       # bob's
  end

  test "admin can open any user's task" do
    sign_in_as(users(:admin))
    get task_url(tasks(:bob_task))
    assert_response :success
    assert_select "h1", tasks(:bob_task).title
  end

  test "admin can delete another user's task" do
    sign_in_as(users(:admin))
    assert_difference("Task.count", -1) do
      delete task_url(tasks(:bob_task))
    end
    assert_redirected_to tasks_url
  end

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
    due_today = @user.tasks.create!(title: "Due today", complete_by: Time.current.end_of_day - 1.hour)
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
    15.times { |i| @user.tasks.create!(title: "Extra #{i}", complete_by: (i + 10).days.from_now) }
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

  test "show renders a task with its author" do
    get task_url(@task)
    assert_response :success
    assert_select "h1", @task.title
    assert_select "p", /Author:.*#{Regexp.escape(@task.user.email)}/m
  end

  test "show renders the description as Markdown" do
    @task.update!(description: "# Heading\n\n- a **bold** item")
    get task_url(@task)
    assert_select ".markdown-body h1", "Heading"
    assert_select ".markdown-body li strong", "bold"
  end

  test "show sanitizes dangerous markup in the description" do
    @task.update!(description: "Hi <script>alert('xss')</script>")
    get task_url(@task)
    rendered = css_select(".markdown-body").first.to_html
    assert_no_match(/<script/, rendered)
  end

  test "markdown_preview returns sanitized html" do
    post markdown_preview_url, params: { text: "# Hi\n\n<script>alert('x')</script>" }, as: :json
    assert_response :success
    html = response.parsed_body["html"]
    assert_match %r{<h1>Hi</h1>}, html
    assert_no_match(/<script/, html)
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

  test "creates a task with supporting files attached" do
    post tasks_url, params: { task: {
      title: "With attachment", complete_by: 2.days.from_now,
      supporting_files: [ fixture_file_upload("sample.txt", "text/plain") ]
    } }
    assert_redirected_to task_url(Task.last)
    assert Task.last.supporting_files.attached?
    assert_equal "sample.txt", Task.last.supporting_files.first.filename.to_s
  end

  test "update appends new files and keeps existing ones" do
    attach_file(@task, "existing.txt")
    assert_equal 1, @task.supporting_files.count

    patch task_url(@task), params: { task: {
      supporting_files: [ fixture_file_upload("sample.txt", "text/plain") ]
    } }
    assert_redirected_to task_url(@task)
    assert_equal 2, @task.reload.supporting_files.count
  end

  test "removing an attachment deletes its blob and stored file immediately" do
    attach_file(@task, "remove_me.txt")
    file = @task.supporting_files.first
    blob = file.blob
    assert ActiveStorage::Blob.service.exist?(blob.key)

    assert_difference([ "ActiveStorage::Attachment.count", "ActiveStorage::Blob.count" ], -1) do
      patch task_url(@task), params: { task: { remove_file_ids: [ file.id ] } }
    end
    assert_not @task.reload.supporting_files.attached?
    assert_not ActiveStorage::Blob.service.exist?(blob.key), "file should be gone from storage"
  end

  test "deleting a task purges its attachments and stored files immediately" do
    attach_file(@task, "a.txt")
    attach_file(@task, "b.txt")
    keys = @task.supporting_files.map { |f| f.blob.key }

    assert_difference([ "ActiveStorage::Attachment.count", "ActiveStorage::Blob.count" ], -2) do
      delete task_url(@task)
    end
    keys.each { |key| assert_not ActiveStorage::Blob.service.exist?(key) }
  end

  test "editing text fields does not drop existing attachments" do
    attach_file(@task, "keep.txt")
    patch task_url(@task), params: { task: { title: "Renamed" } }
    assert_equal "Renamed", @task.reload.title
    assert_equal 1, @task.supporting_files.count
  end

  test "destroys a task" do
    assert_difference("Task.count", -1) do
      delete task_url(@task)
    end
    assert_redirected_to tasks_url
  end

  private

  def sign_in_as(user, password: "password")
    post login_url, params: { email: user.email, password: password }
  end

  def reset_session_for_test
    delete logout_url
  end

  def attach_file(task, filename)
    task.supporting_files.attach(
      io: StringIO.new("content"), filename: filename, content_type: "text/plain"
    )
  end

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
