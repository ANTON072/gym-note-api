# == Schema Information
#
# Table name: workouts
#
#  id                 :bigint           not null, primary key
#  memo               :text(65535)
#  performed_end_at   :datetime
#  performed_start_at :datetime         not null
#  total_volume       :integer          default(0), not null
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  user_id            :bigint           not null
#
# Indexes
#
#  index_workouts_on_user_id  (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#
require "test_helper"

class WorkoutTest < ActiveSupport::TestCase
  def setup
    @user = users(:one)
  end

  test "有効な属性で作成できる" do
    workout = Workout.new(
      user: @user,
      performed_start_at: Time.current,
      performed_end_at: 1.hour.from_now,
      total_volume: 1000,
      memo: "テストワークアウト"
    )
    assert workout.valid?
  end

  test "user_idは必須である" do
    workout = Workout.new(
      performed_start_at: Time.current,
      performed_end_at: 1.hour.from_now,
      total_volume: 1000
    )
    assert_not workout.valid?
    assert_includes workout.errors.details[:user], { error: :blank }
  end

  test "performed_start_atは必須である" do
    workout = Workout.new(
      user: @user,
      performed_end_at: 1.hour.from_now,
      total_volume: 1000
    )
    assert_not workout.valid?
    assert_includes workout.errors.details[:performed_start_at], { error: :blank }
  end

  test "performed_end_atは省略可能である" do
    workout = Workout.new(
      user: @user,
      performed_start_at: Time.current,
      total_volume: 1000
    )
    assert workout.valid?
  end

  test "total_volumeのデフォルト値は0である" do
    workout = Workout.new(
      user: @user,
      performed_start_at: Time.current
    )
    workout.valid?
    assert_equal 0, workout.total_volume
  end

  test "total_volumeは負の値にできない" do
    workout = Workout.new(
      user: @user,
      performed_start_at: Time.current,
      total_volume: -100
    )
    assert_not workout.valid?
    assert_includes workout.errors.details[:total_volume], { error: :greater_than_or_equal_to, count: 0 }
  end

  test "performed_end_atはperformed_start_at以降でなければならない" do
    workout = Workout.new(
      user: @user,
      performed_start_at: Time.current,
      performed_end_at: 1.hour.ago
    )
    assert_not workout.valid?
    assert_includes workout.errors.details[:performed_end_at], { error: :must_be_after_start_time }
  end

  test "memoは省略可能である" do
    workout = Workout.new(
      user: @user,
      performed_start_at: Time.current,
      total_volume: 1000
    )
    assert workout.valid?
    assert_nil workout.memo
  end

  test "userとの関連付けが正しく動作する" do
    workout = Workout.create!(
      user: @user,
      performed_start_at: Time.current,
      total_volume: 1000
    )
    assert_equal @user, workout.user
    assert_includes @user.workouts, workout
  end

  test "userが削除されると関連するworkoutsも削除される" do
    workout = Workout.create!(
      user: @user,
      performed_start_at: Time.current,
      total_volume: 1000
    )
    assert_difference "Workout.count", -1 do
      @user.destroy
    end
  end
end
