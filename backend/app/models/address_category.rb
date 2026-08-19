class AddressCategory < ApplicationRecord
  self.primary_key = "ac_id"

  has_many :addresses,
    foreign_key: :address_category_id, primary_key: :ac_id, inverse_of: :address_category

  validates :ac_name, presence: true

  default_scope { order(:ac_sort) }
end
