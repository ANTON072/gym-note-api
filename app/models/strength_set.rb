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
#  weight              :integer
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  workout_exercise_id :bigint           not null
#
# Indexes
#
#  index_workout_sets_on_type                                 (type)
#  index_workout_sets_on_workout_exercise_id                  (workout_exercise_id)
#  index_workout_sets_on_workout_exercise_id_and_order_index  (workout_exercise_id,order_index) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (workout_exercise_id => workout_exercises.id) ON DELETE => cascade
#
class StrengthSet < WorkoutSet
  validates :weight, presence: true, numericality: { greater_than_or_equal_to: 0 }

  # CardioSetのフィールドは使用しない
  validates :duration_seconds, :calories, absence: true

  # exercise_typeがstrengthであることを確認
  validate :exercise_must_be_strength

  # lateralityに基づくrepsのバリデーション
  validate :validate_reps_by_laterality

  # 総負荷量計算
  def volume
    return 0 if weight.blank?

    if exercise.bilateral?
      weight * (reps || 0)
    else
      weight * ((left_reps || 0) + (right_reps || 0))
    end
  end

  private

  def exercise_must_be_strength
    return unless workout_exercise&.exercise

    unless exercise.strength?
      errors.add(:base, :invalid_exercise_type)
    end
  end

  def validate_reps_by_laterality
    return unless workout_exercise&.exercise

    if exercise.bilateral?
      # 両側の場合：repsが必須、left_reps/right_repsは設定不可
      errors.add(:reps, :blank) if reps.blank?
      errors.add(:reps, :greater_than_or_equal_to, count: 1, value: reps) if reps.present? && reps < 1
      errors.add(:left_reps, :present) if left_reps.present?
      errors.add(:right_reps, :present) if right_reps.present?
    elsif exercise.unilateral?
      # 片側の場合：left_reps/right_repsが必須、repsは設定不可
      errors.add(:left_reps, :blank) if left_reps.blank?
      errors.add(:right_reps, :blank) if right_reps.blank?
      errors.add(:left_reps, :greater_than_or_equal_to, count: 0, value: left_reps) if left_reps.present? && left_reps < 0
      errors.add(:right_reps, :greater_than_or_equal_to, count: 0, value: right_reps) if right_reps.present? && right_reps < 0
      errors.add(:reps, :present) if reps.present?
    end
  end
end
