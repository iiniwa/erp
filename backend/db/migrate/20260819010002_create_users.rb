class CreateUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :users, id: :string, primary_key: :user_code, limit: 9 do |t|
      t.string :user_id
      t.integer :user_type, null: false
      t.string :user_pass, null: false
      t.boolean :user_must_change_password, null: false, default: true
      t.string :user_familyname, null: false
      t.string :user_firstname, null: false
      t.string :user_familyname_ruby, null: false
      t.string :user_firstname_ruby, null: false
      t.date :user_birth
      t.string :user_auth_key
      t.date :user_join_date
      t.integer :user_login_fail_count, null: false, default: 0
      t.boolean :user_is_locked, null: false, default: false
      t.date :user_entry_date, null: false
      t.datetime :user_update_date
      t.datetime :deleted_at

      t.index :user_id, unique: true
      t.index :user_type
      t.index :deleted_at
    end
  end
end
