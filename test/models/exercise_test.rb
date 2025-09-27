# == Schema Information
#
# Table name: exercises
#
#  id         :bigint           not null, primary key
#  body_part  :integer          not null
#  laterality :integer
#  memo       :text(65535)
#  name       :string(255)      not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_exercises_on_body_part  (body_part)
#  index_exercises_on_name       (name) UNIQUE
#
require "test_helper"

class ExerciseTest < ActiveSupport::TestCase
  def setup
    @exercise = Exercise.new(
      name: "ベンチプレス",
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

  test "body_partが必須である" do
    @exercise.body_part = nil
    assert_not @exercise.valid?
    assert_includes @exercise.errors.details[:body_part], { error: :blank }
  end

  test "cardio以外の場合lateralityが必須である" do
    @exercise.body_part = "chest"
    @exercise.laterality = nil
    assert_not @exercise.valid?
    assert_includes @exercise.errors.details[:laterality], { error: :blank }
  end

  test "cardioはbody_partは有効である" do
    @exercise.body_part = "cardio"
    @exercise.laterality = nil
    assert @exercise.valid?
  end

  test "cardioはbody_partでlateralityが設定されている場合は無効である" do
    @exercise.body_part = "cardio"
    @exercise.laterality = "bilateral"
    assert_not @exercise.valid?
    assert_includes @exercise.errors.details[:laterality], { error: :present }
  end

  test "memoは任意項目である" do
    @exercise.memo = nil
    assert @exercise.valid?
  end

  test "body_partの有効な値を受け入れる" do
    valid_body_parts = %w[legs back shoulders arms chest cardio]

    valid_body_parts.each do |body_part|
      exercise = @exercise.dup
      exercise.body_part = body_part
      if body_part == "cardio"
        exercise.laterality = nil
      else
        exercise.laterality = "bilateral"
      end
      assert exercise.valid?, "#{body_part}は有効な値であるべき"
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

  test "無効なbody_partを拒否する" do
    assert_raises(ArgumentError) do
      @exercise.body_part = "invalid_body_part"
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
      laterality: "bilateral",
      body_part: "legs"
    )
    assert exercise.valid?
    assert_not exercise.cardio?
    assert exercise.bilateral?
  end

  test "片側実施の筋力トレーニング例" do
    exercise = Exercise.new(
      name: "ダンベルカール",
      laterality: "unilateral",
      body_part: "arms"
    )
    assert exercise.valid?
    assert_not exercise.cardio?
    assert exercise.unilateral?
  end

  test "有酸素運動の例" do
    exercise = Exercise.new(
      name: "ランニング",
      body_part: "cardio"
    )
    assert exercise.valid?
    assert exercise.cardio?
    assert_nil exercise.laterality
    assert_equal "cardio", exercise.body_part
  end

  # body_part関連のテスト


  test "各部位の筋力トレーニング例" do
    Exercise.body_parts.each_key do |body_part|
      next if body_part == "cardio"
      exercise = Exercise.new(
        name: "Test exercise for #{body_part}",
        laterality: "bilateral",
        body_part: body_part
      )
      assert exercise.valid?, "#{body_part}の筋力トレーニングは有効であるべき"
      assert_not exercise.cardio?
      assert_equal body_part, exercise.body_part
    end
  end

  test "部位別検索が可能である" do
    @exercise.save! # body_part: 'chest'
    Exercise.create!(name: "スクワット-テスト", laterality: "bilateral", body_part: "legs")

    chest_exercises = Exercise.where(body_part: :chest)
    assert_equal 1, chest_exercises.count
    assert_equal "ベンチプレス", chest_exercises.first.name

    legs_exercises = Exercise.where(body_part: :legs)
    assert_equal 1, legs_exercises.count
    assert_equal "スクワット-テスト", legs_exercises.first.name
  end
end
