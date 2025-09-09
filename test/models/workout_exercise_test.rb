require "test_helper"

class WorkoutExerciseTest < ActiveSupport::TestCase
  def setup
    @user = User.create!(username: "testuser", firebase_uid: "firebase123")
    @workout = Workout.create!(
      user: @user,
      workout_date: Date.today,
      location: "自宅"
    )
    @exercise = Exercise.create!(
      name: "ベンチプレス",
      exercise_type: :strength,
      body_part: :chest
    )
  end

  test "有効なworkout_exerciseを作成できる" do
    workout_exercise = WorkoutExercise.new(
      workout: @workout,
      exercise: @exercise,
      order_index: 1
    )
    assert workout_exercise.valid?
  end

  test "workoutがない場合は無効" do
    workout_exercise = WorkoutExercise.new(
      exercise: @exercise,
      order_index: 1
    )
    assert_not workout_exercise.valid?
    assert_includes workout_exercise.errors.details[:workout], { error: :blank }
  end

  test "exerciseがない場合は無効" do
    workout_exercise = WorkoutExercise.new(
      workout: @workout,
      order_index: 1
    )
    assert_not workout_exercise.valid?
    assert_includes workout_exercise.errors.details[:exercise], { error: :blank }
  end

  test "order_indexがない場合は無効" do
    workout_exercise = WorkoutExercise.new(
      workout: @workout,
      exercise: @exercise
    )
    assert_not workout_exercise.valid?
    assert_includes workout_exercise.errors.details[:order_index], { error: :blank }
  end

  test "order_indexは1以上でなければならない" do
    workout_exercise = WorkoutExercise.new(
      workout: @workout,
      exercise: @exercise,
      order_index: 0
    )
    assert_not workout_exercise.valid?
    assert_includes workout_exercise.errors.details[:order_index], { error: :greater_than_or_equal_to, value: 0, count: 1 }
  end

  test "order_indexは整数でなければならない" do
    workout_exercise = WorkoutExercise.new(
      workout: @workout,
      exercise: @exercise,
      order_index: 1.5
    )
    assert_not workout_exercise.valid?
    assert_includes workout_exercise.errors.details[:order_index], { error: :not_an_integer, value: 1.5 }
  end

  test "同じworkout内でorder_indexの重複は許可される" do
    WorkoutExercise.create!(
      workout: @workout,
      exercise: @exercise,
      order_index: 1
    )

    another_exercise = Exercise.create!(
      name: "スクワット",
      exercise_type: :strength,
      body_part: :legs
    )

    workout_exercise = WorkoutExercise.new(
      workout: @workout,
      exercise: another_exercise,
      order_index: 1
    )
    assert workout_exercise.valid?
  end

  test "異なるworkoutでは同じexerciseを使用できる" do
    WorkoutExercise.create!(
      workout: @workout,
      exercise: @exercise,
      order_index: 1
    )

    another_workout = Workout.create!(
      user: @user,
      workout_date: Date.tomorrow,
      location: "ジム"
    )

    workout_exercise = WorkoutExercise.new(
      workout: another_workout,
      exercise: @exercise,
      order_index: 1
    )
    assert workout_exercise.valid?
  end

  test "同じworkoutで同じexerciseは一度しか使用できない" do
    WorkoutExercise.create!(
      workout: @workout,
      exercise: @exercise,
      order_index: 1
    )

    workout_exercise = WorkoutExercise.new(
      workout: @workout,
      exercise: @exercise,
      order_index: 2
    )
    assert_not workout_exercise.valid?
    assert_includes workout_exercise.errors.details[:exercise_id], { error: :taken, value: @exercise.id }
  end

  test "削除時の挙動" do
    workout_exercise = WorkoutExercise.create!(
      workout: @workout,
      exercise: @exercise,
      order_index: 1
    )

    assert_difference("WorkoutExercise.count", -1) do
      workout_exercise.destroy
    end
  end

  test "workoutが削除されたときに関連するworkout_exerciseも削除される" do
    WorkoutExercise.create!(
      workout: @workout,
      exercise: @exercise,
      order_index: 1
    )

    assert_difference("WorkoutExercise.count", -1) do
      @workout.destroy
    end
  end

  test "exerciseが削除されたときにworkout_exerciseの削除は制限される" do
    WorkoutExercise.create!(
      workout: @workout,
      exercise: @exercise,
      order_index: 1
    )

    assert_raises(ActiveRecord::DeleteRestrictionError) do
      @exercise.destroy
    end
  end

  test "workout_exercises_countがキャッシュされる" do
    workout_exercise = WorkoutExercise.create!(
      workout: @workout,
      exercise: @exercise,
      order_index: 1,
      workout_exercises_count: 0
    )

    assert_equal 0, workout_exercise.workout_exercises_count
  end

  test "notesフィールドに長いテキストを保存できる" do
    long_text = "a" * 1000
    workout_exercise = WorkoutExercise.new(
      workout: @workout,
      exercise: @exercise,
      order_index: 1,
      notes: long_text
    )
    assert workout_exercise.valid?
    workout_exercise.save!
    assert_equal long_text, workout_exercise.reload.notes
  end

  test "notesフィールドはnullを許可する" do
    workout_exercise = WorkoutExercise.new(
      workout: @workout,
      exercise: @exercise,
      order_index: 1,
      notes: nil
    )
    assert workout_exercise.valid?
  end

  test "notesフィールドは空文字列を許可する" do
    workout_exercise = WorkoutExercise.new(
      workout: @workout,
      exercise: @exercise,
      order_index: 1,
      notes: ""
    )
    assert workout_exercise.valid?
  end
end
