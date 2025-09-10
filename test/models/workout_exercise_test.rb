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
require "test_helper"

class WorkoutExerciseTest < ActiveSupport::TestCase
  def setup
    @user = User.create!(
      name: "testuser",
      email: "test@example.com",
      firebase_uid: "firebase123"
    )
    @workout = Workout.create!(
      user: @user,
      performed_start_at: Time.current
    )
    @exercise = Exercise.create!(
      name: "ベンチプレス",
      exercise_type: :strength,
      body_part: :chest,
      laterality: :bilateral
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

  test "同じworkout内でorder_indexの重複は許可されない" do
    WorkoutExercise.create!(
      workout: @workout,
      exercise: @exercise,
      order_index: 1
    )

    another_exercise = Exercise.create!(
      name: "スクワット",
      exercise_type: :strength,
      body_part: :legs,
      laterality: :bilateral
    )

    workout_exercise = WorkoutExercise.new(
      workout: @workout,
      exercise: another_exercise,
      order_index: 1
    )
    assert_not workout_exercise.valid?
    assert_includes workout_exercise.errors.details[:order_index], { error: :taken, value: 1 }
  end

  test "異なるworkoutでは同じexerciseを使用できる" do
    WorkoutExercise.create!(
      workout: @workout,
      exercise: @exercise,
      order_index: 1
    )

    another_workout = Workout.create!(
      user: @user,
      performed_start_at: Time.current + 1.day
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

    assert_not @exercise.destroy
    assert @exercise.errors[:base].any?
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

  # total_volume集計メソッドのテスト
  test "total_volumeメソッドはStrengthSetのvolumeの合計を返す" do
    workout_exercise = WorkoutExercise.create!(
      workout: @workout,
      exercise: @exercise,
      order_index: 1
    )

    # StrengthSetを3つ作成
    StrengthSet.create!(
      workout_exercise: workout_exercise,
      order_index: 1,
      weight: 60000,
      reps: 10,
      volume: 600000
    )
    StrengthSet.create!(
      workout_exercise: workout_exercise,
      order_index: 2,
      weight: 60000,
      reps: 8,
      volume: 480000
    )
    StrengthSet.create!(
      workout_exercise: workout_exercise,
      order_index: 3,
      weight: 60000,
      reps: 6,
      volume: 360000
    )

    assert_equal 1440000, workout_exercise.total_volume
  end

  test "CardioSetは総負荷量計算に含まれない" do
    cardio_exercise = Exercise.create!(
      name: "ランニング",
      exercise_type: :cardio
    )

    strength_workout_exercise = WorkoutExercise.create!(
      workout: @workout,
      exercise: @exercise,
      order_index: 1
    )

    cardio_workout_exercise = WorkoutExercise.create!(
      workout: @workout,
      exercise: cardio_exercise,
      order_index: 2
    )

    # StrengthSetを作成
    StrengthSet.create!(
      workout_exercise: strength_workout_exercise,
      order_index: 1,
      weight: 60000,
      reps: 10,
      volume: 600000
    )

    # CardioSetを作成（volumeは0）
    CardioSet.create!(
      workout_exercise: cardio_workout_exercise,
      order_index: 1,
      duration_seconds: 1800,
      calories: 300,
      volume: 0
    )

    assert_equal 600000, strength_workout_exercise.total_volume
    assert_equal 0, cardio_workout_exercise.total_volume
  end

  test "workout_setsがない場合total_volumeは0" do
    workout_exercise = WorkoutExercise.create!(
      workout: @workout,
      exercise: @exercise,
      order_index: 1
    )

    assert_equal 0, workout_exercise.total_volume
  end

  test "片手種目の総負荷量計算も正しく集計される" do
    unilateral_exercise = create_unilateral_exercise

    workout_exercise = WorkoutExercise.create!(
      workout: @workout,
      exercise: unilateral_exercise,
      order_index: 1
    )

    # 片手種目のStrengthSetを作成
    StrengthSet.create!(
      workout_exercise: workout_exercise,
      order_index: 1,
      weight: 20000,
      left_reps: 10,
      right_reps: 12,
      volume: 440000  # 20000 * (10 + 12)
    )
    StrengthSet.create!(
      workout_exercise: workout_exercise,
      order_index: 2,
      weight: 20000,
      left_reps: 8,
      right_reps: 10,
      volume: 360000  # 20000 * (8 + 10)
    )

    assert_equal 800000, workout_exercise.total_volume
  end
end
