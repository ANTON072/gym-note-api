class User < ApplicationRecord
  # Firebase認証用のバリデーション
  validates :firebase_uid, presence: true, uniqueness: true
  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :name, presence: true
end
