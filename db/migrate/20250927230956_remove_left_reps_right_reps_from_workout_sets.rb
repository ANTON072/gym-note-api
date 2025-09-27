class RemoveLeftRepsRightRepsFromWorkoutSets < ActiveRecord::Migration[8.0]
  def change
    remove_column :workout_sets, :left_reps, :integer
    remove_column :workout_sets, :right_reps, :integer
  end
end
