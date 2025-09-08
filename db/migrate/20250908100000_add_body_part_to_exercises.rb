class AddBodyPartToExercises < ActiveRecord::Migration[8.0]
  # 将来のモデル変更でマイグレーションが壊れるのを防ぐため、一時的なモデルを定義します
  class TmpExercise < ApplicationRecord
    self.table_name = 'exercises'
    enum exercise_type: { strength: 0, cardio: 1 }
    enum body_part: { legs: 0, back: 1, shoulders: 2, arms: 3, chest: 4 }
  end

  def up
    add_column :exercises, :body_part, :integer

    # 既存のstrengthタイプのレコードにデフォルト値を設定します
    TmpExercise.where(exercise_type: :strength).update_all(body_part: TmpExercise.body_parts[:chest])

    add_index :exercises, :body_part
    add_index :exercises, [ :exercise_type, :body_part ]
  end

  def down
    remove_index :exercises, name: :index_exercises_on_exercise_type_and_body_part
    remove_index :exercises, name: :index_exercises_on_body_part
    remove_column :exercises, :body_part
  end
end
