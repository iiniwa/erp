class CreateAddressTels < ActiveRecord::Migration[8.1]
  def change
    create_table :address_tels, primary_key: :at_id do |t|
      t.string :address_id, null: false, limit: 9
      t.string :at_number, null: false
      t.integer :at_label_type, null: false
      t.string :at_label_free
      t.integer :at_sort, null: false, default: 1

      # Non-NULL only when at_label_type is "emergency contact" (5), so a
      # unique index on (address_id, emergency_slot) allows at most one
      # emergency-contact row per address while leaving other label types
      # unrestricted (MariaDB unique indexes treat multiple NULLs as distinct).
      t.virtual :emergency_slot,
        type: :integer, as: "(CASE WHEN at_label_type = 5 THEN 1 ELSE NULL END)", stored: true

      t.index :address_id
      t.index [ :address_id, :emergency_slot ], unique: true,
        name: "index_address_tels_on_one_emergency_contact"
    end

    add_foreign_key :address_tels, :addresses, column: :address_id, primary_key: :address_id
  end
end
