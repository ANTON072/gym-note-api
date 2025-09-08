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
require "test_helper"

class UserTest < ActiveSupport::TestCase
  def setup
    @valid_attributes = {
      firebase_uid: "test_uid_123",
      email: "test@example.com",
      name: "Test User"
    }
  end

  test "有効な属性でユーザーを作成できること" do
    user = User.new(@valid_attributes)
    assert user.valid?
  end

  test "firebase_uidなしではユーザーを保存できないこと" do
    user = User.new(@valid_attributes.except(:firebase_uid))
    assert_not user.valid?
    assert_includes user.errors[:firebase_uid], "Firebase UIDを入力してください"
  end

  test "emailなしではユーザーを保存できないこと" do
    user = User.new(@valid_attributes.except(:email))
    assert_not user.valid?
    assert_includes user.errors[:email], "メールアドレスを入力してください"
  end

  test "nameなしではユーザーを保存できないこと" do
    user = User.new(@valid_attributes.except(:name))
    assert_not user.valid?
    assert_includes user.errors[:name], "名前を入力してください"
  end

  test "無効なメールフォーマットではユーザーを保存できないこと" do
    invalid_emails = [ "invalid", "invalid@", "@example.com", "invalid@" ]
    invalid_emails.each do |invalid_email|
      user = User.new(@valid_attributes.merge(email: invalid_email))
      assert_not user.valid?, "#{invalid_email}は無効であるべき"
      assert_includes user.errors[:email], "メールアドレスの形式が正しくありません"
    end
  end

  test "有効なメールフォーマットでユーザーを保存できること" do
    valid_emails = [ "user@example.com", "USER@foo.COM", "A_US-ER@foo.bar.org", "first.last@foo.jp" ]
    valid_emails.each do |valid_email|
      user = User.new(@valid_attributes.merge(email: valid_email))
      assert user.valid?, "#{valid_email}は有効であるべき"
    end
  end

  test "重複するfirebase_uidではユーザーを保存できないこと" do
    User.create!(@valid_attributes)
    duplicate_user = User.new(@valid_attributes.merge(email: "different@example.com", name: "Different Name"))
    assert_not duplicate_user.valid?
    assert_includes duplicate_user.errors[:firebase_uid], "このFirebase UIDはすでに登録されています"
  end

  test "異なるfirebase_uidで複数のユーザーを作成できること" do
    User.create!(@valid_attributes)
    different_user = User.new(@valid_attributes.merge(firebase_uid: "different_uid_456"))
    assert different_user.valid?
  end
end
