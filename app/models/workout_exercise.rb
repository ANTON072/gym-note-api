# == Schema Information
#
# Table name: workout_exercises
#
#  id          :bigint           not null, primary key
#  notes       :text(65535)
#  order_index :integer          not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  exercise_id :bigint           not null
#  workout_id  :bigint           not null
#
# Indexes
#
#  index_workout_exercises_on_exercise_id                 (exercise_id)
#  index_workout_exercises_on_workout_id                  (workout_id)
#  index_workout_exercises_on_workout_id_and_exercise_id  (workout_id,exercise_id) UNIQUE
#  index_workout_exercises_on_workout_id_and_order_index  (workout_id,order_index) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (exercise_id => exercises.id)
#  fk_rails_...  (workout_id => workouts.id)
#
class WorkoutExercise < ApplicationRecord
  belongs_to :workout
  belongs_to :exercise
  has_many :workout_sets, dependent: :destroy
  alias_method :sets, :workout_sets

  validates :order_index, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 1 }, uniqueness: { scope: :workout_id }
  validates :total_volume, numericality: { greater_than_or_equal_to: 0 }
  validates :exercise_id, uniqueness: { scope: :workout_id }

  # exercise_typeに応じたSetサブクラスをbuild
  def build_set(attributes = {})
    if exercise.strength?
      sets.build(attributes.merge(type: "StrengthSet"))
    else
      sets.build(attributes.merge(type: "CardioSet"))
    end
  end

  # exercise_typeに応じたSetサブクラスをcreate
  def create_set!(attributes = {})
    if exercise.strength?
      sets.create!(attributes.merge(type: "StrengthSet"))
    else
      sets.create!(attributes.merge(type: "CardioSet"))
    end
  end
end
