# == Schema Information
#
# Table name: exercises
#
#  id            :bigint           not null, primary key
#  body_part     :integer
#  exercise_type :integer          not null
#  laterality    :integer
#  memo          :text(65535)
#  name          :string(255)      not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#
# Indexes
#
#  index_exercises_on_body_part_and_exercise_type  (body_part,exercise_type)
#  index_exercises_on_exercise_type                (exercise_type)
#  index_exercises_on_name                         (name) UNIQUE
#
class Exercise < ApplicationRecord
  enum :exercise_type, { strength: 0, cardio: 1 }
  enum :laterality, { bilateral: 0, unilateral: 1 }
  enum :body_part, { legs: 0, back: 1, shoulders: 2, arms: 3, chest: 4 }

  validates :name, presence: true, uniqueness: true, length: { maximum: 255 }
  validates :exercise_type, presence: true
  validates :laterality, presence: true, if: :strength?
  validates :laterality, absence: { message: :cardio_cannot_have_laterality }, if: :cardio?
  validates :body_part, presence: true, if: :strength?
  validates :body_part, absence: { message: :cardio_cannot_have_body_part }, if: :cardio?
end
