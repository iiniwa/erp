class CreateFiles < ActiveRecord::Migration[8.1]
  def change
    # t.files (spec section 9): a generic file registry. file_path stores
    # the SFTPGo object key (e.g. "general/8f3.../logo.png"); file_type
    # decides which top-level folder (general vs. archive, spec section
    # 9.3) FileStorageService uploads to. Only "general" is used this
    # phase (archive belongs to a later phase's t.archive feature).
    create_table :files, primary_key: :file_id do |t|
      t.integer :file_type, null: false, default: 1
      t.string :file_path, null: false
      t.string :file_name, null: false
      t.string :content_type
      t.bigint :file_size
      t.string :uploaded_by, limit: 9
      t.datetime :deleted_at

      t.timestamps

      t.index :deleted_at
    end

    add_foreign_key :files, :users, column: :uploaded_by, primary_key: :user_code
  end
end
