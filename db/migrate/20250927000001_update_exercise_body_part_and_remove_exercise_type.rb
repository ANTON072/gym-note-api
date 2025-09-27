class UpdateExerciseBodyPartAndRemoveExerciseType < ActiveRecord::Migration[8.0]
  # 将来のモデル変更でマイグレーションが壊れるのを防ぐため、一時的なモデルを定義します
  class TmpExercise < ApplicationRecord
    self.table_name = 'exercises'
    enum :exercise_type, { strength: 0, cardio: 1 }
    enum :body_part, { legs: 0, back: 1, shoulders: 2, arms: 3, chest: 4, full_body: 5 }
  end

  # downward用の一時的なモデルを定義
  class TmpExerciseDown < ApplicationRecord
    self.table_name = 'exercises'
    enum :exercise_type, { strength: 0, cardio: 1 }
    enum :body_part, { legs: 0, back: 1, shoulders: 2, arms: 3, chest: 4, full_body: 5 }
  end

  def up
    # 既存のfull_bodyをcardioに変更（値を5から5のまま）
    # exercise_typeがcardioのレコードのbody_partをfull_body(5)に設定
    TmpExercise.where(exercise_type: :cardio).update_all(body_part: TmpExercise.body_parts[:full_body])

    # 既存の制約を削除
    remove_check_constraint :exercises, name: "exercises_body_part_null_for_cardio"
    remove_check_constraint :exercises, name: "exercises_body_part_not_null_for_strength"

    # body_partは常に必須に変更
    change_column_null :exercises, :body_part, false

    # exercise_typeカラムとその関連インデックスを削除
    remove_index :exercises, name: "index_exercises_on_body_part_and_exercise_type"
    remove_index :exercises, name: "index_exercises_on_exercise_type"
    remove_column :exercises, :exercise_type

    # body_partのみのインデックスを追加
    add_index :exercises, :body_part
  end

  def down
    # exercise_typeカラムを再追加
    add_column :exercises, :exercise_type, :integer, null: false, default: 0

    # インデックスを再作成
    add_index :exercises, :exercise_type
    add_index :exercises, [ :body_part, :exercise_type ]

    # body_partが5（cardio/full_body）のレコードをcardioに設定
    TmpExerciseDown.where(body_part: 5).update_all(exercise_type: TmpExerciseDown.exercise_types[:cardio])
    # それ以外をstrengthに設定
    TmpExerciseDown.where.not(body_part: 5).update_all(exercise_type: TmpExerciseDown.exercise_types[:strength])

    # 制約を再追加
    strength_value = TmpExerciseDown.exercise_types[:strength]
    add_check_constraint :exercises, "exercise_type != #{strength_value} OR body_part IS NOT NULL", name: "exercises_body_part_not_null_for_strength"

    cardio_value = TmpExerciseDown.exercise_types[:cardio]
    add_check_constraint :exercises, "exercise_type != #{cardio_value} OR body_part IS NULL", name: "exercises_body_part_null_for_cardio"

    # body_partをnullableに戻す
    change_column_null :exercises, :body_part, true

    # body_partのインデックスを削除
    remove_index :exercises, :body_part
  end
end