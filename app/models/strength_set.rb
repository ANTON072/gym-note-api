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
class StrengthSet < WorkoutSet
  validates :weight, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :reps, presence: true, numericality: { greater_than_or_equal_to: 1 }

  # CardioSetのフィールドは使用しない
  validates :duration_seconds, :calories, absence: true

  # exerciseへのアクセスを委譲
  delegate :exercise, to: :workout_exercise


  # body_partがcardio以外であることを確認
  validate :exercise_must_be_strength

  # 保存前にvolumeを自動計算
  before_save :calculate_volume

  # 総負荷量計算（テスト用にpublicメソッドとして残す）
  def volume
    return 0 if weight.blank?

    if exercise.unilateral?
      # 片側の場合：記録された重量は片方なので2倍する
      weight * (reps || 0) * 2
    else
      # 両側の場合：通常の計算
      weight * (reps || 0)
    end
  end

  private

  def calculate_volume
    self.volume = if weight.blank?
                    0
    elsif exercise.unilateral?
                    # 片側の場合：記録された重量は片方なので2倍する
                    weight * (reps || 0) * 2
    else
                    # 両側の場合：通常の計算
                    weight * (reps || 0)
    end
  end

  def exercise_must_be_strength
    return unless workout_exercise&.exercise

    if exercise.cardio?
      errors.add(:base, :invalid_body_part)
    end
  end
end
