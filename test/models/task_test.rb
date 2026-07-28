require "test_helper"

class TaskTest < ActiveSupport::TestCase
  test "is valid with a title and complete_by" do
    task = Task.new(title: "Write docs", complete_by: 1.day.from_now)
    assert task.valid?
  end

  test "strips whitespace from title and description before saving" do
    task = Task.create!(title: "  Write docs  ", description: "  details  ", complete_by: 1.day.from_now)
    assert_equal "Write docs", task.title
    assert_equal "details", task.description
  end

  test "rejects a title that is only whitespace" do
    task = Task.new(title: "   ", complete_by: 1.day.from_now)
    assert_not task.valid?
    assert_includes task.errors[:title], "can't be blank"
  end

  test "requires a title" do
    task = Task.new(complete_by: 1.day.from_now)
    assert_not task.valid?
    assert_includes task.errors[:title], "can't be blank"
  end

  test "requires a complete_by" do
    task = Task.new(title: "No deadline")
    assert_not task.valid?
    assert_includes task.errors[:complete_by], "can't be blank"
  end

  test "completed? reflects completed_at" do
    assert tasks(:done).completed?
    assert_not tasks(:pending_future).completed?
  end

  test "overdue? is true only for past, uncompleted tasks" do
    assert tasks(:overdue).overdue?
    assert_not tasks(:pending_future).overdue?
    assert_not tasks(:done).overdue?, "completed tasks are never overdue"
  end

  test "scopes partition pending and completed" do
    assert_includes Task.pending, tasks(:pending_future)
    assert_includes Task.completed, tasks(:done)
    assert_not_includes Task.pending, tasks(:done)
  end
end
