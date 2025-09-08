class CreateExercises < ActiveRecord::Migration[8.0]
  def change
    create_table :exercises do |t|
      t.string :name, null: false
      t.integer :exercise_type, null: false
      t.integer :laterality
      t.text :memo

      t.timestamps
    end
    add_index :exercises, :name, unique: true
    add_index :exercises, :exercise_type
  end
end
