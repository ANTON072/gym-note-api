# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2025_09_27_231000) do
  create_table "exercises", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.string "name", null: false
    t.integer "laterality"
    t.text "memo"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "body_part", null: false
    t.index ["body_part"], name: "index_exercises_on_body_part"
    t.index ["name"], name: "index_exercises_on_name", unique: true
  end

  create_table "users", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.string "firebase_uid"
    t.string "email"
    t.string "name"
    t.string "image_url"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["firebase_uid"], name: "index_users_on_firebase_uid", unique: true
  end

  create_table "workout_exercises", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.bigint "workout_id", null: false
    t.bigint "exercise_id", null: false
    t.integer "order_index", null: false
    t.text "memo"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["exercise_id"], name: "index_workout_exercises_on_exercise_id"
    t.index ["workout_id", "exercise_id"], name: "index_workout_exercises_on_workout_id_and_exercise_id", unique: true
    t.index ["workout_id", "order_index"], name: "index_workout_exercises_on_workout_id_and_order_index", unique: true
    t.index ["workout_id"], name: "index_workout_exercises_on_workout_id"
  end

  create_table "workout_sets", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.bigint "workout_exercise_id", null: false
    t.string "type", null: false
    t.integer "weight"
    t.integer "reps"
    t.integer "duration_seconds"
    t.integer "calories"
    t.integer "order_index", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "volume", default: 0, null: false
    t.index ["type"], name: "index_workout_sets_on_type"
    t.index ["volume"], name: "index_workout_sets_on_volume"
    t.index ["workout_exercise_id", "order_index"], name: "index_workout_sets_on_workout_exercise_id_and_order_index", unique: true
    t.index ["workout_exercise_id"], name: "index_workout_sets_on_workout_exercise_id"
  end

  create_table "workouts", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.datetime "performed_start_at", null: false
    t.datetime "performed_end_at"
    t.text "memo"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_workouts_on_user_id"
  end

  add_foreign_key "workout_exercises", "exercises"
  add_foreign_key "workout_exercises", "workouts"
  add_foreign_key "workout_sets", "workout_exercises", on_delete: :cascade
  add_foreign_key "workouts", "users"
end
