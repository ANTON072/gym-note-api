# == Schema Information
#
# Table name: exercises
#
#  id         :bigint           not null, primary key
#  body_part  :integer          not null
#  laterality :integer
#  memo       :text(65535)
#  name       :string(255)      not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_exercises_on_body_part  (body_part)
#  index_exercises_on_name       (name) UNIQUE
#
class Exercise < ApplicationRecord
  enum :laterality, { bilateral: 0, unilateral: 1 }
  enum :body_part, { legs: 0, back: 1, shoulders: 2, arms: 3, chest: 4, cardio: 5 }

  has_many :workout_exercises, dependent: :restrict_with_error

  validates :name, presence: true, uniqueness: true, length: { maximum: 255 }
  validates :body_part, presence: true
  validates :laterality, presence: true, unless: :cardio?
  validates :laterality, absence: { message: :cardio_cannot_have_laterality }, if: :cardio?
  validates :memo, length: { maximum: 1000 }

  def cardio?
    body_part == "cardio"
  end
end
