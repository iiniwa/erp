class CreateSystems < ActiveRecord::Migration[8.1]
  def change
    # id: false + a manually added (non-auto-incrementing) primary key: t.system
    # is a singleton, always id=1 (see SystemSetting.instance), and MariaDB
    # rejects a CHECK constraint on an AUTO_INCREMENT column, which is what
    # Rails' usual `primary_key:` shorthand would create here.
    create_table :systems, id: false do |t|
      t.bigint :system_id, null: false
      t.string :system_name
      t.bigint :system_logo_file_id
      t.bigint :system_favicon_file_id
      t.string :company_name
      t.string :company_post
      t.string :company_address
      t.string :company_tel
      t.string :company_email
      t.string :company_invoice_number
      t.string :company_corporate_number
      t.string :representative_position
      t.string :representative_name
      t.bigint :corporate_logo_file_id
      t.bigint :corporate_logotype_file_id
      t.bigint :company_seal_file_id
      t.bigint :company_square_seal_file_id
      t.string :bank_name
      t.string :bank_branch_name
      t.integer :bank_account_type
      t.string :bank_account_number
      t.string :bank_account_holder
      t.decimal :default_tax_rate, precision: 5, scale: 2
      t.integer :fiscal_year_end_month
      t.integer :login_lockout_count, null: false, default: 10
      t.datetime :updated_at
      t.string :updated_by, limit: 9

      # t.system is a singleton table (id=1 fixed, per spec section 10.1). The
      # application also enforces this, but a DB-level check constraint makes
      # it impossible to ever insert a second row regardless of caller.
      t.check_constraint "system_id = 1", name: "systems_singleton_id"
    end

    reversible do |dir|
      dir.up { execute "ALTER TABLE systems ADD PRIMARY KEY (system_id)" }
      dir.down { execute "ALTER TABLE systems DROP PRIMARY KEY" }
    end

    add_foreign_key :systems, :users, column: :updated_by, primary_key: :user_code
  end
end
