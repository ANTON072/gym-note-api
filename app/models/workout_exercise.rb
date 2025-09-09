class WorkoutExercise < ApplicationRecord
  belongs_to :workout
  belongs_to :exercise

  validates :order_index, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 1 }
  validates :total_volume, numericality: { greater_than_or_equal_to: 0 }
  validates :exercise_id, uniqueness: { scope: :workout_id }
end