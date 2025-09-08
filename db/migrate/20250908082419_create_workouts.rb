class CreateWorkouts < ActiveRecord::Migration[8.0]
  def change
    create_table :workouts do |t|
      t.references :user, null: false, foreign_key: true
      t.datetime :performed_start_at, null: false
      t.datetime :performed_end_at
      t.integer :total_volume, null: false, default: 0
      t.text :memo

      t.timestamps
    end
  end
end
