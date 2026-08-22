class AddUniqueIndexToAddressesAddressUserCode < ActiveRecord::Migration[8.1]
  # An employee has at most one linked address book entry, now that it's
  # exclusively managed via Employee Management (see
  # Api::V1::EmployeeAddressesController) rather than picked from a
  # dropdown on the address book form. NULL (business contacts, not
  # linked to any employee) stays unrestricted — MariaDB unique indexes
  # treat multiple NULLs as distinct.
  #
  # Explicit up/down (not #change): the duplicate-check SELECT below uses
  # `execute`, which Rails can't auto-reverse.
  def up
    # remove_foreign_key/remove_index below are separate DDL statements
    # from add_index; if duplicate address_user_code values already exist,
    # add_index would fail *after* those have already run, leaving the
    # original FK/index gone with no unique index to replace them. Fail
    # up front instead, before touching anything, with a message that
    # says what to fix rather than a bare duplicate-key DDL error.
    duplicates = execute(<<~SQL).to_a
      SELECT address_user_code, COUNT(*) AS row_count
      FROM addresses
      WHERE address_user_code IS NOT NULL
      GROUP BY address_user_code
      HAVING COUNT(*) > 1
    SQL

    if duplicates.any?
      # execute's result rows come back as plain arrays here, not
      # hashes — address_user_code is the first selected column.
      codes = duplicates.map { |row| row[0] }.join(", ")
      raise ActiveRecord::IrreversibleMigration,
        "Cannot add a unique index on addresses.address_user_code: multiple address rows " \
        "already reference the same employee (address_user_code: #{codes}). Resolve these " \
        "duplicates manually (decide which address to keep per employee) before re-running " \
        "this migration."
    end

    remove_foreign_key :addresses, :users, column: :address_user_code
    remove_index :addresses, :address_user_code
    add_index :addresses, :address_user_code, unique: true
    add_foreign_key :addresses, :users, column: :address_user_code, primary_key: :user_code
  end

  def down
    remove_foreign_key :addresses, :users, column: :address_user_code
    remove_index :addresses, :address_user_code
    add_index :addresses, :address_user_code
    add_foreign_key :addresses, :users, column: :address_user_code, primary_key: :user_code
  end
end
