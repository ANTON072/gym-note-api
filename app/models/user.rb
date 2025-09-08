# == Schema Information
#
# Table name: users
#
#  id           :bigint           not null, primary key
#  email        :string(255)
#  firebase_uid :string(255)
#  image_url    :string(255)
#  name         :string(255)
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#
# Indexes
#
#  index_users_on_firebase_uid  (firebase_uid) UNIQUE
#
class User < ApplicationRecord
  # Firebase認証用のバリデーション
  validates :firebase_uid, presence: true, uniqueness: true
  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :name, presence: true
end
