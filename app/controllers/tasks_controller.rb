class TasksController < ApplicationController
  PER_PAGE = 10
  FILTERS = %w[all today overdue pending completed].freeze

  before_action :set_task, only: %i[show edit update destroy toggle]

  def index
    @filter = FILTERS.include?(params[:filter]) ? params[:filter] : "all"
    @query = params[:q].to_s.strip
    @counts = filter_counts

    scope = filtered_scope(@filter).by_deadline
    scope = scope.search(@query) if @query.present?

    # Simple, dependency-free pagination.
    @per_page = PER_PAGE
    @total_count = scope.count
    @total_pages = [ (@total_count.to_f / @per_page).ceil, 1 ].max
    @page = params[:page].to_i.clamp(1, @total_pages)
    @tasks = scope.offset((@page - 1) * @per_page).limit(@per_page)
    @list_payload = list_payload

    respond_to do |format|
      format.html
      format.json { render json: @list_payload }
    end
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

  # Everything the Vue list needs to render one page of results.
  def list_payload
    {
      tasks: @tasks.map { |task| helpers.task_payload(task) },
      filter: @filter,
      query: @query,
      counts: @counts,
      page: @page,
      total_pages: @total_pages,
      total_count: @total_count,
      per_page: @per_page
    }
  end

  def filtered_scope(filter)
    case filter
    when "today"     then Task.due_by_end_of_today
    when "overdue"   then Task.overdue
    when "pending"   then Task.pending
    when "completed" then Task.completed
    else Task.all
    end
  end

  # Totals per filter for the tab badges (independent of the current search).
  def filter_counts
    {
      "all" => Task.count,
      "today" => Task.due_by_end_of_today.count,
      "overdue" => Task.overdue.count,
      "pending" => Task.pending.count,
      "completed" => Task.completed.count
    }
  end

  def set_task
    @task = Task.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to tasks_path, alert: "Task not found."
  end

  def task_params
    params.require(:task).permit(:title, :description, :complete_by)
  end
end
