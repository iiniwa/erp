class AddressPolicy < ApplicationPolicy
  private

  def pm_code
    "address_book"
  end
end
