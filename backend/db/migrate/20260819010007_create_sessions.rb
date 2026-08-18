class CreateSessions < ActiveRecord::Migration[8.1]
  def change
    create_table :sessions, primary_key: :session_id do |t|
      t.string :user_code, null: false, limit: 9
      t.string :session_token, null: false
      t.integer :session_mode, null: false, default: 1
      t.string :ip_address
      t.string :user_agent
      t.datetime :expires_at, null: false
      t.datetime :created_at, null: false

      t.index :user_code
      t.index :session_token, unique: true
    end

    add_foreign_key :sessions, :users, column: :user_code, primary_key: :user_code
  end
end
