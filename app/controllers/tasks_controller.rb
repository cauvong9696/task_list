class TasksController < ApplicationController
  before_action :set_task, only: %i[show edit update destroy toggle]

  def index
    @tasks = Task.order(completed_at: :asc, complete_by: :asc)
  end

  def show
  end

  def new
    @task = Task.new

    # "Copy" opens this form pre-filled from an existing task; nothing is saved
    # until the user submits.
    if (source = Task.find_by(id: params[:copy_from]))
      @task.title = "#{source.title} (copy)"
      @task.description = source.description
      @task.complete_by = source.complete_by
    end
  end

  def create
    @task = Task.new(task_params)

    if @task.save
      redirect_to @task, notice: "Task was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @task.update(task_params)
      redirect_to @task, notice: "Task was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @task.destroy
    redirect_to tasks_path, notice: "Task was successfully deleted."
  end

  # Flip a task between completed and pending.
  def toggle
    @task.update(completed_at: @task.completed? ? nil : Time.current)
    redirect_back fallback_location: tasks_path
  end

  private

  def set_task
    @task = Task.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to tasks_path, alert: "Task not found."
  end

  def task_params
    params.require(:task).permit(:title, :description, :complete_by)
  end
end
