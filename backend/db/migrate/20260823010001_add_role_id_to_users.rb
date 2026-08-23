# Independent of user_type (spec section 5.1's employment classification,
# still used for retirement/system_admin protection): role_id is the
# freely admin-managed permission level (see PermissionRole) an employee
# is assigned to. Nullable — an employee with no role assigned simply has
# no RBAC-governed access, same as before an admin configures anything.
class AddRoleIdToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :role_id, :bigint
    add_index :users, :role_id
    add_foreign_key :users, :permission_roles, column: :role_id, primary_key: :role_id
  end
end
