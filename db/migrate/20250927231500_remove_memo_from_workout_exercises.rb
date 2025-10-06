class RemoveMemoFromWorkoutExercises < ActiveRecord::Migration[8.0]
  def change
    remove_column :workout_exercises, :memo, :text
  end
end
