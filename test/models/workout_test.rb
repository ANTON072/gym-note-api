# == Schema Information
#
# Table name: workouts
#
#  id                 :bigint           not null, primary key
#  memo               :text(65535)
#  performed_end_at   :datetime
#  performed_start_at :datetime         not null
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  user_id            :bigint           not null
#
# Indexes
#
#  index_workouts_on_user_id  (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#
require "test_helper"

class WorkoutTest < ActiveSupport::TestCase
  def setup
    @user = users(:one)
  end

  test "有効な属性で作成できる" do
    workout = Workout.new(
      user: @user,
      performed_start_at: Time.current,
      performed_end_at: 1.hour.from_now,
      memo: "テストワークアウト"
    )
    assert workout.valid?
  end

  test "user_idは必須である" do
    workout = Workout.new(
      performed_start_at: Time.current,
      performed_end_at: 1.hour.from_now
    )
    assert_not workout.valid?
    assert_includes workout.errors.details[:user], { error: :blank }
  end

  test "performed_start_atは必須である" do
    workout = Workout.new(
      user: @user,
      performed_end_at: 1.hour.from_now
    )
    assert_not workout.valid?
    assert_includes workout.errors.details[:performed_start_at], { error: :blank }
  end

  test "performed_end_atは省略可能である" do
    workout = Workout.new(
      user: @user,
      performed_start_at: Time.current
    )
    assert workout.valid?
  end


  test "performed_end_atはperformed_start_at以降でなければならない" do
    workout = Workout.new(
      user: @user,
      performed_start_at: Time.current,
      performed_end_at: 1.hour.ago
    )
    assert_not workout.valid?
    assert_includes workout.errors.details[:performed_end_at], { error: :must_be_after_start_time }
  end

  test "memoは省略可能である" do
    workout = Workout.new(
      user: @user,
      performed_start_at: Time.current
    )
    assert workout.valid?
    assert_nil workout.memo
  end

  test "userとの関連付けが正しく動作する" do
    workout = Workout.create!(
      user: @user,
      performed_start_at: Time.current
    )
    assert_equal @user, workout.user
    assert_includes @user.workouts, workout
  end

  test "userが削除されると関連するworkoutsも削除される" do
    workout = Workout.create!(
      user: @user,
      performed_start_at: Time.current
    )
    assert_difference "Workout.count", -1 do
      @user.destroy
    end
  end

  # total_volume集計メソッドのテスト
  test "total_volumeメソッドは全ての種目のvolumeの合計を返す" do
    workout = Workout.create!(
      user: @user,
      performed_start_at: Time.current
    )

    # 筋トレ種目を2つ作成
    exercise1 = create_bilateral_exercise
    exercise2 = create_unilateral_exercise
    
    workout_exercise1 = WorkoutExercise.create!(
      workout: workout,
      exercise: exercise1,
      order_index: 1
    )
    
    workout_exercise2 = WorkoutExercise.create!(
      workout: workout,
      exercise: exercise2,
      order_index: 2
    )

    # exercise1のセット
    StrengthSet.create!(
      workout_exercise: workout_exercise1,
      order_index: 1,
      weight: 60000,
      reps: 10,
      volume: 600000
    )
    StrengthSet.create!(
      workout_exercise: workout_exercise1,
      order_index: 2,
      weight: 60000,
      reps: 8,
      volume: 480000
    )

    # exercise2のセット
    StrengthSet.create!(
      workout_exercise: workout_exercise2,
      order_index: 1,
      weight: 20000,
      left_reps: 10,
      right_reps: 12,
      volume: 440000
    )

    assert_equal 1520000, workout.total_volume  # 600000 + 480000 + 440000
  end

  test "有酸素運動のみの場合total_volumeは0" do
    workout = Workout.create!(
      user: @user,
      performed_start_at: Time.current
    )

    cardio_exercise = create_cardio_exercise
    
    workout_exercise = WorkoutExercise.create!(
      workout: workout,
      exercise: cardio_exercise,
      order_index: 1
    )

    CardioSet.create!(
      workout_exercise: workout_exercise,
      order_index: 1,
      duration_seconds: 1800,
      calories: 300,
      volume: 0
    )
    CardioSet.create!(
      workout_exercise: workout_exercise,
      order_index: 2,
      duration_seconds: 1200,
      calories: 200,
      volume: 0
    )

    assert_equal 0, workout.total_volume
  end

  test "筋トレと有酸素運動が混在する場合は筋トレのvolumeのみ集計" do
    workout = Workout.create!(
      user: @user,
      performed_start_at: Time.current
    )

    strength_exercise = create_bilateral_exercise
    cardio_exercise = create_cardio_exercise
    
    strength_workout_exercise = WorkoutExercise.create!(
      workout: workout,
      exercise: strength_exercise,
      order_index: 1
    )
    
    cardio_workout_exercise = WorkoutExercise.create!(
      workout: workout,
      exercise: cardio_exercise,
      order_index: 2
    )

    # 筋トレセット
    StrengthSet.create!(
      workout_exercise: strength_workout_exercise,
      order_index: 1,
      weight: 60000,
      reps: 10,
      volume: 600000
    )

    # 有酸素セット
    CardioSet.create!(
      workout_exercise: cardio_workout_exercise,
      order_index: 1,
      duration_seconds: 1800,
      calories: 300,
      volume: 0
    )

    assert_equal 600000, workout.total_volume
  end

  test "workout_exercisesがない場合total_volumeは0" do
    workout = Workout.create!(
      user: @user,
      performed_start_at: Time.current
    )

    assert_equal 0, workout.total_volume
  end

  test "複数の種目で複数のセットがある場合の複雑な集計" do
    workout = Workout.create!(
      user: @user,
      performed_start_at: Time.current
    )

    # 3つの種目を作成
    bench_press = Exercise.create!(
      name: "ベンチプレス",
      exercise_type: :strength,
      body_part: :chest,
      laterality: :bilateral
    )
    dumbbell_fly = create_unilateral_exercise
    running = create_cardio_exercise

    # WorkoutExerciseを作成
    bench_workout_exercise = WorkoutExercise.create!(
      workout: workout,
      exercise: bench_press,
      order_index: 1
    )
    
    fly_workout_exercise = WorkoutExercise.create!(
      workout: workout,
      exercise: dumbbell_fly,
      order_index: 2
    )
    
    running_workout_exercise = WorkoutExercise.create!(
      workout: workout,
      exercise: running,
      order_index: 3
    )

    # ベンチプレスのセット (3セット)
    StrengthSet.create!(workout_exercise: bench_workout_exercise, order_index: 1, weight: 80000, reps: 10, volume: 800000)
    StrengthSet.create!(workout_exercise: bench_workout_exercise, order_index: 2, weight: 85000, reps: 8, volume: 680000)
    StrengthSet.create!(workout_exercise: bench_workout_exercise, order_index: 3, weight: 90000, reps: 6, volume: 540000)

    # ダンベルフライのセット (2セット)
    StrengthSet.create!(workout_exercise: fly_workout_exercise, order_index: 1, weight: 15000, left_reps: 12, right_reps: 12, volume: 360000)
    StrengthSet.create!(workout_exercise: fly_workout_exercise, order_index: 2, weight: 15000, left_reps: 10, right_reps: 10, volume: 300000)

    # ランニング
    CardioSet.create!(workout_exercise: running_workout_exercise, order_index: 1, duration_seconds: 1800, calories: 300, volume: 0)

    # 合計: 800000 + 680000 + 540000 + 360000 + 300000 = 2680000
    assert_equal 2680000, workout.total_volume
  end
end
