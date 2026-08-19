class CreatePermissionMasters < ActiveRecord::Migration[8.1]
  def change
    create_table :permission_masters, primary_key: :pm_id do |t|
      t.string :pm_code, null: false
      t.string :pm_name, null: false
      t.integer :pm_sort, null: false, default: 0

      t.index :pm_code, unique: true
    end
  end
end
