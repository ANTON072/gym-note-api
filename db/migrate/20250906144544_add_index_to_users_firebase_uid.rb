class AddIndexToUsersFirebaseUid < ActiveRecord::Migration[8.0]
  def change
    add_index :users, :firebase_uid, unique: true
  end
end
