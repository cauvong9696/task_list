class Task < ApplicationRecord
  belongs_to :user

  has_many_attached :supporting_files

  normalizes :title, with: ->(value) { value.strip }
  normalizes :description, with: ->(value) { value.strip }

  validates :title, presence: true
  validates :complete_by, presence: true

  scope :pending, -> { where(completed_at: nil) }
  scope :completed, -> { where.not(completed_at: nil) }
  scope :overdue, -> { pending.where(complete_by: ...Time.current) }
  scope :due_by_end_of_today, -> { where(complete_by: ..Time.current.end_of_day) }
  scope :by_deadline, -> { order(complete_by: :asc) }
  scope :search, ->(term) { where("title ILIKE :q OR description ILIKE :q", q: "%#{term}%") }

  def completed?
    completed_at.present?
  end

  # Pending and already past its complete-by time.
  def overdue?
    !completed? && complete_by.present? && complete_by.past?
  end
end
