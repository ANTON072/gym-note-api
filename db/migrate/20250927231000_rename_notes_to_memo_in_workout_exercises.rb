class RenameNotesToMemoInWorkoutExercises < ActiveRecord::Migration[8.0]
  def change
    rename_column :workout_exercises, :notes, :memo
  end
end
