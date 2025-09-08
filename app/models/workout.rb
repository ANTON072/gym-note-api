class Workout < ApplicationRecord
  belongs_to :user

  validates :performed_start_at, presence: true
  validates :total_volume, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validate :end_time_after_start_time

  before_validation :set_default_total_volume

  private

  def set_default_total_volume
    self.total_volume ||= 0
  end

  def end_time_after_start_time
    return unless performed_start_at && performed_end_at

    if performed_end_at <= performed_start_at
      errors.add(:performed_end_at, "must be after start time")
    end
  end
end