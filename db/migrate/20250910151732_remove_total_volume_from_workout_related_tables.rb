class RemoveTotalVolumeFromWorkoutRelatedTables < ActiveRecord::Migration[8.0]
  def change
    remove_column :workout_exercises, :total_volume, :integer
    remove_column :workouts, :total_volume, :integer
  end
end
