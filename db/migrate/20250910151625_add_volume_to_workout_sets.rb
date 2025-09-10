class AddVolumeToWorkoutSets < ActiveRecord::Migration[8.0]
  def change
    add_column :workout_sets, :volume, :integer, default: 0, null: false
    add_index :workout_sets, :volume
  end
end
