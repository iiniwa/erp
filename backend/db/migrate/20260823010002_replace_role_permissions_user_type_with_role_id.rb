# Replaces the fixed rp_user_type enum key with a role_id referencing the
# freely admin-creatable/deletable permission_roles table. No production
# data exists yet for this column, so existing rows are cleared rather
# than backfilled.
class ReplaceRolePermissionsUserTypeWithRoleId < ActiveRecord::Migration[8.1]
  def up
    execute "DELETE FROM role_permissions"

    remove_index :role_permissions, name: "index_role_permissions_on_rp_user_type_and_pm_id"
    remove_column :role_permissions, :rp_user_type

    add_column :role_permissions, :role_id, :bigint, null: false
    add_index :role_permissions, [ :role_id, :pm_id ], unique: true
    add_foreign_key :role_permissions, :permission_roles, column: :role_id, primary_key: :role_id
  end

  def down
    execute "DELETE FROM role_permissions"

    remove_foreign_key :role_permissions, column: :role_id
    remove_index :role_permissions, [ :role_id, :pm_id ]
    remove_column :role_permissions, :role_id

    add_column :role_permissions, :rp_user_type, :integer, null: false
    add_index :role_permissions, [ :rp_user_type, :pm_id ], unique: true,
      name: "index_role_permissions_on_rp_user_type_and_pm_id"
  end
end
