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
require "test_helper"

class StrengthSetTest < ActiveSupport::TestCase
  setup do
    @user = create_test_user
    @exercise = create_bilateral_exercise
    @workout = create_test_workout(user: @user)
    @workout_exercise = create_workout_exercise(
      workout: @workout,
      exercise: @exercise,
      order_index: 1
    )
  end

  # 基本的なStrengthSetのテスト
  test "weightの必須バリデーション" do
    set = StrengthSet.new(
      workout_exercise: @workout_exercise,
      order_index: 1,
      reps: 10
    )
    assert_not set.valid?
    assert_includes set.errors.details[:weight], { error: :blank }
  end

  test "weightが0以上のバリデーション" do
    set = StrengthSet.new(
      workout_exercise: @workout_exercise,
      order_index: 1,
      weight: -100,
      reps: 10
    )
    assert_not set.valid?
    assert_includes set.errors.details[:weight], { error: :greater_than_or_equal_to, value: -100, count: 0 }
  end

  test "repsの必須バリデーション" do
    set = StrengthSet.new(
      workout_exercise: @workout_exercise,
      order_index: 1,
      weight: 60000
    )
    assert_not set.valid?
    assert_includes set.errors.details[:reps], { error: :blank }
  end

  test "repsが1以上のバリデーション" do
    set = StrengthSet.new(
      workout_exercise: @workout_exercise,
      order_index: 1,
      weight: 60000,
      reps: 0
    )
    assert_not set.valid?
    assert_includes set.errors.details[:reps], { error: :greater_than_or_equal_to, value: 0, count: 1 }
  end


  test "正常なセット作成" do
    set = StrengthSet.new(
      workout_exercise: @workout_exercise,
      order_index: 1,
      weight: 60000,
      reps: 10
    )
    assert set.valid?
  end

  # CardioSetのフィールドが設定されていたらエラー
  test "duration_secondsが設定されていたらエラー" do
    set = StrengthSet.new(
      workout_exercise: @workout_exercise,
      order_index: 1,
      weight: 60000,
      reps: 10,
      duration_seconds: 300
    )
    assert_not set.valid?
    assert_includes set.errors.details[:duration_seconds], { error: :present }
  end

  test "caloriesが設定されていたらエラー" do
    set = StrengthSet.new(
      workout_exercise: @workout_exercise,
      order_index: 1,
      weight: 60000,
      reps: 10,
      calories: 100
    )
    assert_not set.valid?
    assert_includes set.errors.details[:calories], { error: :present }
  end

  # 総負荷量計算のテスト
  test "bilateral種目の総負荷量計算" do
    set = StrengthSet.new(
      workout_exercise: @workout_exercise,
      weight: 60000,
      reps: 10
    )
    assert_equal 600000, set.volume
  end

  test "unilateral種目の総負荷量計算（重量を2倍）" do
    unilateral_exercise = create_unilateral_exercise
    unilateral_workout_exercise = create_workout_exercise(
      workout: @workout,
      exercise: unilateral_exercise,
      order_index: 2
    )

    set = StrengthSet.new(
      workout_exercise: unilateral_workout_exercise,
      weight: 20000,  # 片方の重量
      reps: 10
    )
    assert_equal 400000, set.volume  # 20000 * 10 * 2
  end

  test "weightが0の場合volumeは0" do
    set = StrengthSet.new(
      workout_exercise: @workout_exercise,
      weight: 0,
      reps: 10
    )
    assert_equal 0, set.volume
  end

  test "weightがnilの場合volumeは0" do
    set = StrengthSet.new(
      workout_exercise: @workout_exercise,
      weight: nil,
      reps: 10
    )
    assert_equal 0, set.volume
  end

  # volume自動計算のテスト（DBカラムへの保存）
  test "bilateral種目のセット保存時にvolumeが自動計算される" do
    set = StrengthSet.create!(
      workout_exercise: @workout_exercise,
      order_index: 1,
      weight: 60000,
      reps: 10
    )
    assert_equal 600000, set.reload.volume
  end

  test "unilateral種目のセット保存時にvolumeが自動計算される（重量2倍）" do
    unilateral_exercise = create_unilateral_exercise
    unilateral_workout_exercise = create_workout_exercise(
      workout: @workout,
      exercise: unilateral_exercise,
      order_index: 2
    )

    set = StrengthSet.create!(
      workout_exercise: unilateral_workout_exercise,
      order_index: 1,
      weight: 20000,  # 片方の重量
      reps: 10
    )
    assert_equal 400000, set.reload.volume  # 20000 * 10 * 2
  end

  test "更新時にもvolumeが再計算される" do
    set = StrengthSet.create!(
      workout_exercise: @workout_exercise,
      order_index: 1,
      weight: 60000,
      reps: 10
    )
    assert_equal 600000, set.reload.volume

    set.update!(weight: 80000, reps: 8)
    assert_equal 640000, set.reload.volume
  end
end
