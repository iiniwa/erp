class ChangeAddressTelEmergencyToFlag < ActiveRecord::Migration[8.1]
  # Emergency contact moves from being an at_label_type enum value (5) to
  # its own boolean flag (is_emergency), independent of what kind of
  # number it is (mobile/home/etc.) — a business decision made after
  # initial implementation, not something the original spec called for.
  # No production data exists yet, so this rewrites the constraint rather
  # than migrating historical rows.
  def up
    remove_index :address_tels, name: "index_address_tels_on_one_emergency_contact"
    remove_column :address_tels, :emergency_slot

    add_column :address_tels, :is_emergency, :boolean, null: false, default: false

    # Non-NULL only when is_emergency is true, so a unique index on
    # (address_id, emergency_slot) allows at most one emergency-contact
    # row per address while leaving everything else unrestricted (MariaDB
    # unique indexes treat multiple NULLs as distinct).
    add_column :address_tels, :emergency_slot, :virtual,
      type: :integer, as: "(CASE WHEN is_emergency THEN 1 ELSE NULL END)", stored: true
    add_index :address_tels, [ :address_id, :emergency_slot ], unique: true,
      name: "index_address_tels_on_one_emergency_contact"
  end

  def down
    remove_index :address_tels, name: "index_address_tels_on_one_emergency_contact"
    remove_column :address_tels, :emergency_slot
    remove_column :address_tels, :is_emergency

    add_column :address_tels, :emergency_slot, :virtual,
      type: :integer, as: "(CASE WHEN at_label_type = 5 THEN 1 ELSE NULL END)", stored: true
    add_index :address_tels, [ :address_id, :emergency_slot ], unique: true,
      name: "index_address_tels_on_one_emergency_contact"
  end
end
