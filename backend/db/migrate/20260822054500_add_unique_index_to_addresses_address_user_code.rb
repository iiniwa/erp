class AddUniqueIndexToAddressesAddressUserCode < ActiveRecord::Migration[8.1]
  # An employee has at most one linked address book entry, now that it's
  # exclusively managed via Employee Management (see
  # Api::V1::EmployeeAddressesController) rather than picked from a
  # dropdown on the address book form. NULL (business contacts, not
  # linked to any employee) stays unrestricted — MariaDB unique indexes
  # treat multiple NULLs as distinct.
  def change
    remove_foreign_key :addresses, :users, column: :address_user_code
    remove_index :addresses, :address_user_code
    add_index :addresses, :address_user_code, unique: true
    add_foreign_key :addresses, :users, column: :address_user_code, primary_key: :user_code
  end
end
