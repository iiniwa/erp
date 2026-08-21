# Categories are picklist data for the address book form, so they're
# gated by the same "address_book" permission as AddressPolicy rather
# than having their own separate pm_code.
class AddressCategoryPolicy < ApplicationPolicy
  private

  def pm_code
    "address_book"
  end
end
