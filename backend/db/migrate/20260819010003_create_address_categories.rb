class CreateAddressCategories < ActiveRecord::Migration[8.1]
  def change
    create_table :address_categories, primary_key: :ac_id do |t|
      t.string :ac_name, null: false
      t.integer :ac_sort, null: false, default: 0
    end
  end
end
