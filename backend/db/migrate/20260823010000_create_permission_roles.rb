class CreatePermissionRoles < ActiveRecord::Migration[8.1]
  def change
    create_table :permission_roles, primary_key: :role_id do |t|
      t.string :role_name, null: false
      t.integer :role_sort, null: false, default: 0

      t.index :role_name, unique: true
    end
  end
end
