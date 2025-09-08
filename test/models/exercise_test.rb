# == Schema Information
#
# Table name: exercises
#
#  id            :bigint           not null, primary key
#  body_part     :integer
#  exercise_type :integer          not null
#  laterality    :integer
#  memo          :text(65535)
#  name          :string(255)      not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#
# Indexes
#
#  index_exercises_on_body_part_and_exercise_type  (body_part,exercise_type)
#  index_exercises_on_exercise_type                (exercise_type)
#  index_exercises_on_name                         (name) UNIQUE
#
require "test_helper"

class ExerciseTest < ActiveSupport::TestCase
  def setup
    @exercise = Exercise.new(
      name: "ベンチプレス",
      exercise_type: "strength",
      laterality: "bilateral",
      body_part: "chest",
      memo: "胸部の基本種目"
    )
  end

  test "有効なエクササイズを作成できる" do
    assert @exercise.valid?
  end

  test "nameが必須である" do
    @exercise.name = ""
    assert_not @exercise.valid?
    assert_includes @exercise.errors.details[:name], { error: :blank }
  end

  test "nameが一意である" do
    @exercise.save!
    duplicate_exercise = @exercise.dup
    assert_not duplicate_exercise.valid?
    assert_includes duplicate_exercise.errors.details[:name], { error: :taken, value: "ベンチプレス" }
  end

  test "nameの最大文字数は255文字である" do
    @exercise.name = "a" * 256
    assert_not @exercise.valid?
    assert_includes @exercise.errors.details[:name], { error: :too_long, count: 255 }
  end

  test "exercise_typeが必須である" do
    @exercise.exercise_type = nil
    assert_not @exercise.valid?
    assert_includes @exercise.errors.details[:exercise_type], { error: :blank }
  end

  test "strengthタイプの場合lateralityが必須である" do
    @exercise.exercise_type = "strength"
    @exercise.laterality = nil
    assert_not @exercise.valid?
    assert_includes @exercise.errors.details[:laterality], { error: :blank }
  end

  test "cardioタイプは有効である" do
    @exercise.exercise_type = "cardio"
    @exercise.laterality = nil
    @exercise.body_part = nil
    assert @exercise.valid?
  end

  test "cardioタイプでlateralityが設定されている場合は無効である" do
    @exercise.exercise_type = "cardio"
    @exercise.laterality = "bilateral"
    @exercise.body_part = nil
    assert_not @exercise.valid?
    assert_includes @exercise.errors.details[:laterality], { error: :present }
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
        exercise.body_part = nil
      else
        exercise.laterality = "bilateral"
        exercise.body_part = "chest"
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
      laterality: "bilateral",
      body_part: "legs"
    )
    assert exercise.valid?
    assert exercise.strength?
    assert exercise.bilateral?
  end

  test "片側実施の筋力トレーニング例" do
    exercise = Exercise.new(
      name: "ダンベルカール",
      exercise_type: "strength",
      laterality: "unilateral",
      body_part: "arms"
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
    assert_nil exercise.body_part
  end

  # body_part関連のテスト
  test "strengthタイプの場合body_partが必須である" do
    @exercise.exercise_type = "strength"
    @exercise.body_part = nil
    assert_not @exercise.valid?
    assert_includes @exercise.errors.details[:body_part], { error: :blank }
  end


  test "cardioタイプでbody_partが設定されている場合は無効である" do
    @exercise.exercise_type = "cardio"
    @exercise.laterality = nil
    @exercise.body_part = "chest"
    assert_not @exercise.valid?
    assert_includes @exercise.errors.details[:body_part], { error: :present }
  end

  test "body_partの有効な値を受け入れる" do
    Exercise.body_parts.keys.each do |body_part|
      exercise = @exercise.dup
      exercise.body_part = body_part
      assert exercise.valid?, "#{body_part}は有効な値であるべき"
    end
  end

  test "無効なbody_partを拒否する" do
    assert_raises(ArgumentError) do
      @exercise.body_part = "invalid_body_part"
    end
  end

  test "各部位の筋力トレーニング例" do
    body_parts_examples = {
      "legs" => "スクワット",
      "back" => "プルアップ",
      "shoulders" => "ショルダープレス",
      "arms" => "ダンベルカール",
      "chest" => "ベンチプレス"
    }

    body_parts_examples.each do |body_part, name|
      exercise = Exercise.new(
        name: "#{name}-#{body_part}",
        exercise_type: "strength",
        laterality: "bilateral",
        body_part: body_part
      )
      assert exercise.valid?, "#{body_part}の筋力トレーニングは有効であるべき"
      assert exercise.strength?
      assert_equal body_part, exercise.body_part
    end
  end

  test "部位別検索が可能である" do
    @exercise.save! # body_part: 'chest'
    Exercise.create!(name: "スクワット-テスト", exercise_type: "strength", laterality: "bilateral", body_part: "legs")

    chest_exercises = Exercise.where(body_part: :chest)
    assert_equal 1, chest_exercises.count
    assert_equal "ベンチプレス", chest_exercises.first.name

    legs_exercises = Exercise.where(body_part: :legs)
    assert_equal 1, legs_exercises.count
    assert_equal "スクワット-テスト", legs_exercises.first.name
  end
end
