require "test_helper"

class StrengthSetTest < ActiveSupport::TestCase
  setup do
    @user = User.create!(
      firebase_uid: "test_uid_#{SecureRandom.hex(10)}",
      email: "test_#{SecureRandom.hex(10)}@example.com",
      name: "テストユーザー"
    )
    @bilateral_exercise = Exercise.create!(
      name: "ベンチプレス",
      exercise_type: :strength,
      laterality: :bilateral
    )
    @unilateral_exercise = Exercise.create!(
      name: "ダンベルカール",
      exercise_type: :strength,
      laterality: :unilateral
    )
    @workout = Workout.create!(
      user: @user,
      performed_start_at: Time.current
    )
    @bilateral_workout_exercise = WorkoutExercise.create!(
      workout: @workout,
      exercise: @bilateral_exercise,
      order_index: 1
    )
    @unilateral_workout_exercise = WorkoutExercise.create!(
      workout: @workout,
      exercise: @unilateral_exercise,
      order_index: 2
    )
  end

  # 基本的なStrengthSetのテスト
  test "weightの必須バリデーション" do
    set = StrengthSet.new(
      workout_exercise: @bilateral_workout_exercise,
      order_index: 1,
      reps: 10
    )
    assert_not set.valid?
    assert_includes set.errors.details[:weight], { error: :blank }
  end

  test "weightが0以上のバリデーション" do
    set = StrengthSet.new(
      workout_exercise: @bilateral_workout_exercise,
      order_index: 1,
      weight: -100,
      reps: 10
    )
    assert_not set.valid?
    assert_includes set.errors.details[:weight], { error: :greater_than_or_equal_to, count: 0 }
  end

  # bilateral（両側）の場合のテスト
  test "bilateralの場合はrepsが必須" do
    set = StrengthSet.new(
      workout_exercise: @bilateral_workout_exercise,
      order_index: 1,
      weight: 60000
    )
    assert_not set.valid?
    assert_includes set.errors.details[:reps], { error: :blank }
  end

  test "bilateralの場合はrepsが1以上" do
    set = StrengthSet.new(
      workout_exercise: @bilateral_workout_exercise,
      order_index: 1,
      weight: 60000,
      reps: 0
    )
    assert_not set.valid?
    assert_includes set.errors.details[:reps], { error: :greater_than_or_equal_to, count: 1 }
  end

  test "bilateralの場合はleft_repsが設定されていたらエラー" do
    set = StrengthSet.new(
      workout_exercise: @bilateral_workout_exercise,
      order_index: 1,
      weight: 60000,
      reps: 10,
      left_reps: 5
    )
    assert_not set.valid?
    assert_includes set.errors.details[:left_reps], { error: :present }
  end

  test "bilateralの場合はright_repsが設定されていたらエラー" do
    set = StrengthSet.new(
      workout_exercise: @bilateral_workout_exercise,
      order_index: 1,
      weight: 60000,
      reps: 10,
      right_reps: 5
    )
    assert_not set.valid?
    assert_includes set.errors.details[:right_reps], { error: :present }
  end

  test "bilateralの場合の正常なセット作成" do
    set = StrengthSet.new(
      workout_exercise: @bilateral_workout_exercise,
      order_index: 1,
      weight: 60000,
      reps: 10
    )
    assert set.valid?
  end

  # unilateral（片側）の場合のテスト
  test "unilateralの場合はleft_repsが必須" do
    set = StrengthSet.new(
      workout_exercise: @unilateral_workout_exercise,
      order_index: 1,
      weight: 20000,
      right_reps: 10
    )
    assert_not set.valid?
    assert_includes set.errors.details[:left_reps], { error: :blank }
  end

  test "unilateralの場合はright_repsが必須" do
    set = StrengthSet.new(
      workout_exercise: @unilateral_workout_exercise,
      order_index: 1,
      weight: 20000,
      left_reps: 10
    )
    assert_not set.valid?
    assert_includes set.errors.details[:right_reps], { error: :blank }
  end

  test "unilateralの場合はleft_repsが0以上" do
    set = StrengthSet.new(
      workout_exercise: @unilateral_workout_exercise,
      order_index: 1,
      weight: 20000,
      left_reps: -1,
      right_reps: 10
    )
    assert_not set.valid?
    assert_includes set.errors.details[:left_reps], { error: :greater_than_or_equal_to, count: 0 }
  end

  test "unilateralの場合はright_repsが0以上" do
    set = StrengthSet.new(
      workout_exercise: @unilateral_workout_exercise,
      order_index: 1,
      weight: 20000,
      left_reps: 10,
      right_reps: -1
    )
    assert_not set.valid?
    assert_includes set.errors.details[:right_reps], { error: :greater_than_or_equal_to, count: 0 }
  end

  test "unilateralの場合はrepsが設定されていたらエラー" do
    set = StrengthSet.new(
      workout_exercise: @unilateral_workout_exercise,
      order_index: 1,
      weight: 20000,
      left_reps: 10,
      right_reps: 10,
      reps: 10
    )
    assert_not set.valid?
    assert_includes set.errors.details[:reps], { error: :present }
  end

  test "unilateralの場合の正常なセット作成" do
    set = StrengthSet.new(
      workout_exercise: @unilateral_workout_exercise,
      order_index: 1,
      weight: 20000,
      left_reps: 10,
      right_reps: 12
    )
    assert set.valid?
  end

  test "unilateralの場合、片側だけ0回も許可する" do
    set = StrengthSet.new(
      workout_exercise: @unilateral_workout_exercise,
      order_index: 1,
      weight: 20000,
      left_reps: 0,
      right_reps: 10
    )
    assert set.valid?
  end

  # CardioSetのフィールドが設定されていたらエラー
  test "duration_secondsが設定されていたらエラー" do
    set = StrengthSet.new(
      workout_exercise: @bilateral_workout_exercise,
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
      workout_exercise: @bilateral_workout_exercise,
      order_index: 1,
      weight: 60000,
      reps: 10,
      calories: 100
    )
    assert_not set.valid?
    assert_includes set.errors.details[:calories], { error: :present }
  end

  # 総負荷量計算のテスト
  test "bilateralの場合の総負荷量計算" do
    set = StrengthSet.new(
      workout_exercise: @bilateral_workout_exercise,
      weight: 60000,
      reps: 10
    )
    assert_equal 600000, set.volume
  end

  test "unilateralの場合の総負荷量計算" do
    set = StrengthSet.new(
      workout_exercise: @unilateral_workout_exercise,
      weight: 20000,
      left_reps: 10,
      right_reps: 12
    )
    assert_equal 440000, set.volume  # 20000 * (10 + 12)
  end
end
