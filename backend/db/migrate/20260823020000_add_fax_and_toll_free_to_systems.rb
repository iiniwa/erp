class AddFaxAndTollFreeToSystems < ActiveRecord::Migration[8.1]
  def change
    add_column :systems, :company_fax, :string
    add_column :systems, :company_toll_free, :string
  end
end
