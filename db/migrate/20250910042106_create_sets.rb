class CreateSets < ActiveRecord::Migration[8.0]
  def change
    create_table :sets do |t|
      t.references :workout_exercise, null: false, foreign_key: { on_delete: :cascade }
      t.string :type, null: false
      t.integer :weight, null: true
      t.integer :reps, null: true
      t.integer :left_reps, null: true
      t.integer :right_reps, null: true
      t.integer :duration_seconds, null: true
      t.integer :calories, null: true
      t.integer :order_index, null: false

      t.timestamps
    end

    add_index :sets, :type
    add_index :sets, [ :workout_exercise_id, :order_index ], unique: true
  end
end
