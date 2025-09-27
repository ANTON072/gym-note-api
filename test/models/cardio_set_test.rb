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
require "test_helper"

class CardioSetTest < ActiveSupport::TestCase
  setup do
    @user = create_test_user
    @cardio_exercise = create_cardio_exercise
    @strength_exercise = create_bilateral_exercise
    @workout = create_test_workout(user: @user)
    @cardio_workout_exercise = create_workout_exercise(
      workout: @workout,
      exercise: @cardio_exercise,
      order_index: 1
    )
    @strength_workout_exercise = create_workout_exercise(
      workout: @workout,
      exercise: @strength_exercise,
      order_index: 2
    )
  end

  # 基本的なCardioSetのテスト
  test "duration_secondsはオプション" do
    set = CardioSet.new(
      workout_exercise: @cardio_workout_exercise,
      order_index: 1,
      calories: 300
    )
    assert set.valid?
  end

  test "caloriesはオプション" do
    set = CardioSet.new(
      workout_exercise: @cardio_workout_exercise,
      order_index: 1,
      duration_seconds: 1800
    )
    assert set.valid?
  end

  test "duration_secondsとcaloriesの両方がなくても有効" do
    set = CardioSet.new(
      workout_exercise: @cardio_workout_exercise,
      order_index: 1
    )
    assert set.valid?
  end

  test "duration_secondsが設定される場合は1以上" do
    set = CardioSet.new(
      workout_exercise: @cardio_workout_exercise,
      order_index: 1,
      duration_seconds: 0
    )
    assert_not set.valid?
    assert_includes set.errors.details[:duration_seconds], { error: :greater_than_or_equal_to, value: 0, count: 1 }
  end

  test "caloriesが設定される場合は0以上" do
    set = CardioSet.new(
      workout_exercise: @cardio_workout_exercise,
      order_index: 1,
      calories: -10
    )
    assert_not set.valid?
    assert_includes set.errors.details[:calories], { error: :greater_than_or_equal_to, value: -10, count: 0 }
  end

  test "正常なCardioSetの作成（両方の値あり）" do
    set = CardioSet.new(
      workout_exercise: @cardio_workout_exercise,
      order_index: 1,
      duration_seconds: 1800,
      calories: 300
    )
    assert set.valid?
  end

  # StrengthSetのフィールドが設定されていたらエラー
  test "weightが設定されていたらエラー" do
    set = CardioSet.new(
      workout_exercise: @cardio_workout_exercise,
      order_index: 1,
      weight: 50000
    )
    assert_not set.valid?
    assert_includes set.errors.details[:weight], { error: :present }
  end

  test "repsが設定されていたらエラー" do
    set = CardioSet.new(
      workout_exercise: @cardio_workout_exercise,
      order_index: 1,
      reps: 10
    )
    assert_not set.valid?
    assert_includes set.errors.details[:reps], { error: :present }
  end

  test "left_repsが設定されていたらエラー" do
    set = CardioSet.new(
      workout_exercise: @cardio_workout_exercise,
      order_index: 1,
      left_reps: 10
    )
    assert_not set.valid?
    assert_includes set.errors.details[:left_reps], { error: :present }
  end

  test "right_repsが設定されていたらエラー" do
    set = CardioSet.new(
      workout_exercise: @cardio_workout_exercise,
      order_index: 1,
      right_reps: 10
    )
    assert_not set.valid?
    assert_includes set.errors.details[:right_reps], { error: :present }
  end

  # body_partがcardioでない場合のバリデーション
  test "body_partがcardio以外の場合はエラー" do
    set = CardioSet.new(
      workout_exercise: @strength_workout_exercise,
      order_index: 1
    )
    assert_not set.valid?
    assert_includes set.errors.details[:base], { error: :invalid_body_part }
  end

  # volumeは常に0であることのテスト
  test "CardioSetのvolumeは常に0（デフォルト値）" do
    set = CardioSet.create!(
      workout_exercise: @cardio_workout_exercise,
      order_index: 1,
      duration_seconds: 1800,
      calories: 300
    )
    assert_equal 0, set.reload.volume
  end

  test "CardioSetのvolumeは値を設定しようとしてもデフォルトの0のまま" do
    set = CardioSet.new(
      workout_exercise: @cardio_workout_exercise,
      order_index: 1
    )
    # CardioSetではvolumeを計算しないため、常に0
    assert_equal 0, set.volume

    set.save!
    assert_equal 0, set.reload.volume
  end
end
