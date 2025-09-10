# == Schema Information
#
# Table name: workout_sets
#
#  id                  :bigint           not null, primary key
#  calories            :integer
#  duration_seconds    :integer
#  left_reps           :integer
#  order_index         :integer          not null
#  reps                :integer
#  right_reps          :integer
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
class CardioSet < WorkoutSet
  # duration_secondsとcaloriesはオプション
  validates :duration_seconds, numericality: { greater_than_or_equal_to: 1 }, allow_blank: true
  validates :calories, numericality: { greater_than_or_equal_to: 0 }, allow_blank: true

  # StrengthSetのフィールドは使用しない
  validates :weight, :reps, :left_reps, :right_reps, absence: true

  # exercise_typeがcardioであることを確認
  validate :exercise_must_be_cardio

  private

  def exercise_must_be_cardio
    return unless workout_exercise&.exercise

    unless exercise.cardio?
      errors.add(:base, :invalid_exercise_type)
    end
  end
end
