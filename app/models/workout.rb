# == Schema Information
#
# Table name: workouts
#
#  id                 :bigint           not null, primary key
#  memo               :text(65535)
#  performed_end_at   :datetime
#  performed_start_at :datetime         not null
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
class Workout < ApplicationRecord
  belongs_to :user
  has_many :workout_exercises, dependent: :destroy

  validates :performed_start_at, presence: true
  validates :total_volume, numericality: { greater_than_or_equal_to: 0 }
  validate :end_time_after_start_time

  before_validation :set_default_total_volume

  private

  def set_default_total_volume
    self.total_volume ||= 0
  end

  def end_time_after_start_time
    return unless performed_start_at && performed_end_at

    if performed_end_at <= performed_start_at
      errors.add(:performed_end_at, :must_be_after_start_time)
    end
  end
end
