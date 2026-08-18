class Address < ApplicationRecord
  include CodeGeneratable
  include SoftDeletable

  self.primary_key = "address_id"

  belongs_to :address_category,
    foreign_key: :address_category_id, primary_key: :ac_id, inverse_of: :addresses
  belongs_to :user,
    foreign_key: :address_user_code, primary_key: :user_code, optional: true, inverse_of: :addresses
  # No `dependent:` option: addresses are soft-deleted (see SoftDeletable),
  # which never fires Rails' destroy callbacks, so a dependent behavior here
  # would silently never run. The DB foreign keys restrict hard-deleting an
  # address that still has tel/email rows, by design.
  has_many :address_tels, foreign_key: :address_id, primary_key: :address_id, inverse_of: :address
  has_many :address_emails, foreign_key: :address_id, primary_key: :address_id, inverse_of: :address

  validates :address_name, :address_ruby, presence: true

  before_create :assign_address_id

  private

  def assign_address_id
    self.address_id ||= self.class.generate_code(type_code: "8")
  end
end
