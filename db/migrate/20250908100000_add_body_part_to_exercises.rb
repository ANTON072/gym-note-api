class AddBodyPartToExercises < ActiveRecord::Migration[8.0]
  def change
    add_column :exercises, :body_part, :integer
    add_index :exercises, :body_part
    add_index :exercises, [ :exercise_type, :body_part ]
  end
end
