class AddBodyPartToExercises < ActiveRecord::Migration[8.0]
  # 将来のモデル変更でマイグレーションが壊れるのを防ぐため、一時的なモデルを定義します
  class TmpExercise < ApplicationRecord
    self.table_name = 'exercises'
  end

  def up
    add_column :exercises, :body_part, :integer
    add_index :exercises, :body_part
    add_index :exercises, [:exercise_type, :body_part]

    # 既存のstrengthタイプのレコードにデフォルト値を設定します
    # strength は 0, デフォルト部位として chest (4) を設定
    TmpExercise.where(exercise_type: 0).update_all(body_part: 4)
  end

  def down
    remove_index :exercises, [:exercise_type, :body_part]
    remove_index :exercises, :body_part
    remove_column :exercises, :body_part
  end
end
