class CreateAddresses < ActiveRecord::Migration[8.1]
  def change
    create_table :addresses, id: :string, primary_key: :address_id, limit: 9 do |t|
      t.bigint :address_category_id, null: false
      t.string :address_name, null: false
      t.string :address_ruby, null: false
      t.string :address_user_code, limit: 9
      t.string :address_contact_name
      t.string :address_post
      t.string :address_residence
      t.text :address_memo
      t.datetime :deleted_at

      t.timestamps

      t.index :address_category_id
      t.index :address_user_code
      t.index :deleted_at
    end

    add_foreign_key :addresses, :address_categories, column: :address_category_id, primary_key: :ac_id
    add_foreign_key :addresses, :users, column: :address_user_code, primary_key: :user_code
  end
end
