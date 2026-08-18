class CreateRolePermissions < ActiveRecord::Migration[8.1]
  def change
    create_table :role_permissions, primary_key: :rp_id do |t|
      t.integer :rp_user_type, null: false
      t.bigint :pm_id, null: false
      t.boolean :rp_can_view, null: false, default: false
      t.boolean :rp_can_create, null: false, default: false
      t.boolean :rp_can_update, null: false, default: false
      t.boolean :rp_can_delete, null: false, default: false

      t.index :pm_id
      t.index [ :rp_user_type, :pm_id ], unique: true
    end

    add_foreign_key :role_permissions, :permission_masters, column: :pm_id, primary_key: :pm_id
  end
end
