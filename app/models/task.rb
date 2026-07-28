class Task < ApplicationRecord
  normalizes :title, with: ->(value) { value.strip }
  normalizes :description, with: ->(value) { value.strip }

  validates :title, presence: true
  validates :complete_by, presence: true

  scope :pending, -> { where(completed_at: nil) }
  scope :completed, -> { where.not(completed_at: nil) }

  def completed?
    completed_at.present?
  end

  # Pending and already past its complete-by time.
  def overdue?
    !completed? && complete_by.present? && complete_by.past?
  end
end
