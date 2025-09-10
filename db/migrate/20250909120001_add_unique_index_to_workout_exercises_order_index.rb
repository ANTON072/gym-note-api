class AddUniqueIndexToWorkoutExercisesOrderIndex < ActiveRecord::Migration[8.0]
  def change
    remove_index :workout_exercises, [ :workout_id, :order_index ]
    add_index :workout_exercises, [ :workout_id, :order_index ], unique: true
  end
end
