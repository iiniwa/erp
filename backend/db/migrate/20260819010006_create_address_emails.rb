class CreateAddressEmails < ActiveRecord::Migration[8.1]
  def change
    create_table :address_emails, primary_key: :ae_id do |t|
      t.string :address_id, null: false, limit: 9
      t.string :ae_email, null: false
      t.string :ae_label
      t.integer :ae_sort, null: false, default: 1

      t.index :address_id
    end

    add_foreign_key :address_emails, :addresses, column: :address_id, primary_key: :address_id
  end
end
