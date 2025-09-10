ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require "mocha/minitest"

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Add more helper methods to be used by all tests here...

    # 共通のテストデータ作成ヘルパーメソッド
    def create_test_user
      User.create!(
        firebase_uid: "test_uid_#{SecureRandom.hex(10)}",
        email: "test_#{SecureRandom.hex(10)}@example.com",
        name: "テストユーザー"
      )
    end

    def create_test_workout(user:)
      Workout.create!(
        user: user,
        performed_start_at: Time.current
      )
    end

    def create_bilateral_exercise(name: "ベンチプレス", body_part: :chest)
      Exercise.create!(
        name: name,
        exercise_type: :strength,
        laterality: :bilateral,
        body_part: body_part
      )
    end

    def create_unilateral_exercise(name: "ダンベルカール", body_part: :arms)
      Exercise.create!(
        name: name,
        exercise_type: :strength,
        laterality: :unilateral,
        body_part: body_part
      )
    end

    def create_cardio_exercise(name: "トレッドミル")
      Exercise.create!(
        name: name,
        exercise_type: :cardio
      )
    end

    def create_workout_exercise(workout:, exercise:, order_index:)
      WorkoutExercise.create!(
        workout: workout,
        exercise: exercise,
        order_index: order_index
      )
    end
  end
end
