# == Schema Information
#
# Table name: workout_sets
#
#  id                  :bigint           not null, primary key
#  calories            :integer
#  duration_seconds    :integer
#  order_index         :integer          not null
#  reps                :integer
#  type                :string(255)      not null
#  volume              :integer          default(0), not null
#  weight              :integer
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  workout_exercise_id :bigint           not null
#
# Indexes
#
#  index_workout_sets_on_type                                 (type)
#  index_workout_sets_on_volume                               (volume)
#  index_workout_sets_on_workout_exercise_id                  (workout_exercise_id)
#  index_workout_sets_on_workout_exercise_id_and_order_index  (workout_exercise_id,order_index) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (workout_exercise_id => workout_exercises.id) ON DELETE => cascade
#
class WorkoutSet < ApplicationRecord
  belongs_to :workout_exercise
  delegate :exercise, :workout, to: :workout_exercise

  validates :type, presence: true
  validates :order_index, presence: true, numericality: { greater_than_or_equal_to: 1 }
  validates :order_index, uniqueness: { scope: :workout_exercise_id }
end
