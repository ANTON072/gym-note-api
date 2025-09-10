class CreateWorkoutExercises < ActiveRecord::Migration[8.0]
  def change
    create_table :workout_exercises do |t|
      t.references :workout, null: false, foreign_key: true
      t.references :exercise, null: false, foreign_key: { on_delete: :restrict }
      t.integer :order_index, null: false
      t.integer :total_volume, default: 0, null: false
      t.text :notes

      t.timestamps
    end

    add_index :workout_exercises, [ :workout_id, :exercise_id ], unique: true
    add_index :workout_exercises, [ :workout_id, :order_index ]
  end
end
