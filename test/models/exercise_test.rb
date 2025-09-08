# == Schema Information
#
# Table name: exercises
#
#  id            :bigint           not null, primary key
#  exercise_type :integer          not null
#  laterality    :integer
#  memo          :text(65535)
#  name          :string(255)      not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#
# Indexes
#
#  index_exercises_on_exercise_type  (exercise_type)
#  index_exercises_on_name           (name) UNIQUE
#
require "test_helper"

class ExerciseTest < ActiveSupport::TestCase
  def setup
    @exercise = Exercise.new(
      name: "ベンチプレス",
      exercise_type: "strength",
      laterality: "bilateral",
      memo: "胸部の基本種目"
    )
  end

  test "有効なエクササイズを作成できる" do
    assert @exercise.valid?
  end

  test "nameが必須である" do
    @exercise.name = ""
    assert_not @exercise.valid?
    assert_includes @exercise.errors[:name], "を入力してください"
  end

  test "nameが一意である" do
    @exercise.save!
    duplicate_exercise = @exercise.dup
    assert_not duplicate_exercise.valid?
    assert_includes duplicate_exercise.errors[:name], "はすでに存在します"
  end

  test "nameの最大文字数は255文字である" do
    @exercise.name = "a" * 256
    assert_not @exercise.valid?
    assert_includes @exercise.errors[:name], "は255文字以内で入力してください"
  end

  test "exercise_typeが必須である" do
    @exercise.exercise_type = nil
    assert_not @exercise.valid?
    assert_includes @exercise.errors[:exercise_type], "を入力してください"
  end

  test "strengthタイプの場合lateralityが必須である" do
    @exercise.exercise_type = "strength"
    @exercise.laterality = nil
    assert_not @exercise.valid?
    assert_includes @exercise.errors[:laterality], "を入力してください"
  end

  test "cardioタイプの場合lateralityは必ずnilである" do
    @exercise.exercise_type = "cardio"
    @exercise.laterality = nil
    assert @exercise.valid?
  end

  test "cardioタイプでlateralityが設定されている場合は無効である" do
    @exercise.exercise_type = "cardio"
    @exercise.laterality = "bilateral"
    assert_not @exercise.valid?
    assert_includes @exercise.errors[:laterality], "有酸素運動の場合、実施形態は設定できません"
  end

  test "memoは任意項目である" do
    @exercise.memo = nil
    assert @exercise.valid?
  end

  test "exercise_typeの有効な値を受け入れる" do
    valid_exercise_types = %w[strength cardio]

    valid_exercise_types.each do |exercise_type|
      exercise = @exercise.dup
      exercise.exercise_type = exercise_type
      if exercise_type == "cardio"
        exercise.laterality = nil
      else
        exercise.laterality = "bilateral"
      end
      assert exercise.valid?, "#{exercise_type}は有効な値であるべき"
    end
  end

  test "lateralityの有効な値を受け入れる" do
    valid_lateralities = %w[bilateral unilateral]

    valid_lateralities.each do |laterality|
      exercise = @exercise.dup
      exercise.laterality = laterality
      assert exercise.valid?, "#{laterality}は有効な値であるべき"
    end
  end

  test "無効なexercise_typeを拒否する" do
    assert_raises(ArgumentError) do
      @exercise.exercise_type = "invalid_type"
    end
  end

  test "無効なlateralityを拒否する" do
    assert_raises(ArgumentError) do
      @exercise.laterality = "invalid_laterality"
    end
  end

  test "両側実施の筋力トレーニング例" do
    exercise = Exercise.new(
      name: "スクワット",
      exercise_type: "strength",
      laterality: "bilateral"
    )
    assert exercise.valid?
    assert exercise.strength?
    assert exercise.bilateral?
  end

  test "片側実施の筋力トレーニング例" do
    exercise = Exercise.new(
      name: "ダンベルカール",
      exercise_type: "strength",
      laterality: "unilateral"
    )
    assert exercise.valid?
    assert exercise.strength?
    assert exercise.unilateral?
  end

  test "有酸素運動の例" do
    exercise = Exercise.new(
      name: "ランニング",
      exercise_type: "cardio"
    )
    assert exercise.valid?
    assert exercise.cardio?
    assert_nil exercise.laterality
  end
end
