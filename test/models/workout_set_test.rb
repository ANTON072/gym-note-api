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
require "test_helper"

class WorkoutSetTest < ActiveSupport::TestCase
  setup do
    @user = User.create!(
      firebase_uid: "test_uid_#{SecureRandom.hex(10)}",
      email: "test_#{SecureRandom.hex(10)}@example.com",
      name: "テストユーザー"
    )
    @strength_exercise = Exercise.create!(
      name: "ベンチプレス",
      exercise_type: :strength,
      laterality: :bilateral,
      body_part: :chest
    )
    @cardio_exercise = Exercise.create!(
      name: "トレッドミル",
      exercise_type: :cardio
    )
    @workout = Workout.create!(
      user: @user,
      performed_start_at: Time.current
    )
    @strength_workout_exercise = WorkoutExercise.create!(
      workout: @workout,
      exercise: @strength_exercise,
      order_index: 1
    )
    @cardio_workout_exercise = WorkoutExercise.create!(
      workout: @workout,
      exercise: @cardio_exercise,
      order_index: 2
    )
  end

  test "STI親クラスとしてWorkoutSetが機能する" do
    set = WorkoutSet.new(
      workout_exercise: @strength_workout_exercise,
      order_index: 1
    )
    # typeは自動設定されないとエラーになることを確認
    assert_not set.valid?
    assert_includes set.errors.details[:type], { error: :blank }
  end

  test "order_indexの必須バリデーション" do
    set = StrengthSet.new(
      workout_exercise: @strength_workout_exercise
    )
    assert_not set.valid?
    assert_includes set.errors.details[:order_index], { error: :blank }
  end

  test "order_indexが1以上のバリデーション" do
    set = StrengthSet.new(
      workout_exercise: @strength_workout_exercise,
      order_index: 0
    )
    assert_not set.valid?
    assert_includes set.errors.details[:order_index], { error: :greater_than_or_equal_to, count: 1 }
  end

  test "workout_exerciseの必須バリデーション" do
    set = StrengthSet.new(
      order_index: 1
    )
    assert_not set.valid?
    assert_includes set.errors.details[:workout_exercise], { error: :blank }
  end

  test "同じworkout_exerciseでorder_indexの重複を許可しない" do
    StrengthSet.create!(
      workout_exercise: @strength_workout_exercise,
      order_index: 1,
      weight: 60000,
      reps: 10
    )

    duplicate_set = StrengthSet.new(
      workout_exercise: @strength_workout_exercise,
      order_index: 1,
      weight: 50000,
      reps: 8
    )
    assert_not duplicate_set.valid?
    assert_includes duplicate_set.errors.details[:order_index], { error: :taken, value: 1 }
  end

  test "異なるworkout_exerciseで同じorder_indexを許可する" do
    StrengthSet.create!(
      workout_exercise: @strength_workout_exercise,
      order_index: 1,
      weight: 60000,
      reps: 10
    )

    another_set = CardioSet.new(
      workout_exercise: @cardio_workout_exercise,
      order_index: 1,
      duration_seconds: 1800,
      calories: 300
    )
    assert another_set.valid?
  end

  test "exerciseへのデリゲートが機能する" do
    set = StrengthSet.new(
      workout_exercise: @strength_workout_exercise,
      order_index: 1
    )
    assert_equal @strength_exercise, set.exercise
  end

  test "workoutへのデリゲートが機能する" do
    set = StrengthSet.new(
      workout_exercise: @strength_workout_exercise,
      order_index: 1
    )
    assert_equal @workout, set.workout
  end

  test "workout_exerciseが削除されたらsetも削除される" do
    set = StrengthSet.create!(
      workout_exercise: @strength_workout_exercise,
      order_index: 1,
      weight: 60000,
      reps: 10
    )

    assert_difference "WorkoutSet.count", -1 do
      @strength_workout_exercise.destroy
    end
  end

  test "build_setでexercise_typeに応じたSTIクラスが作成される" do
    # strengthの場合
    strength_set = @strength_workout_exercise.build_set(
      order_index: 1,
      weight: 60000,
      reps: 10
    )
    assert_instance_of StrengthSet, strength_set
    assert_equal "StrengthSet", strength_set.type

    # cardioの場合
    cardio_set = @cardio_workout_exercise.build_set(
      order_index: 1,
      duration_seconds: 1800,
      calories: 300
    )
    assert_instance_of CardioSet, cardio_set
    assert_equal "CardioSet", cardio_set.type
  end

  test "create_setでexercise_typeに応じたSTIクラスが作成される" do
    # strengthの場合
    strength_set = @strength_workout_exercise.create_set!(
      order_index: 1,
      weight: 60000,
      reps: 10
    )
    assert_instance_of StrengthSet, strength_set
    assert_equal "StrengthSet", strength_set.type
    assert strength_set.persisted?

    # cardioの場合
    cardio_set = @cardio_workout_exercise.create_set!(
      order_index: 1,
      duration_seconds: 1800,
      calories: 300
    )
    assert_instance_of CardioSet, cardio_set
    assert_equal "CardioSet", cardio_set.type
    assert cardio_set.persisted?
  end
end
