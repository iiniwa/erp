require "rails_helper"

RSpec.describe Address do
  subject { create(:address) }

  it_behaves_like "a soft-deletable model"

  it "assigns an address_id formatted as 8YYMMNNN on create" do
    travel_to Time.zone.local(2026, 8, 19, 12, 0, 0) do
      address = create(:address)
      expect(address.address_id).to match(/\A8\d{7}\z/)
      expect(address.address_id).to start_with("82608")
    end
  end

  it "allows an address with no associated user (e.g. a business contact)" do
    address = build(:address, user: nil)
    expect(address).to be_valid
  end

  it "allows an address linked to an employee" do
    user = create(:user)
    address = build(:address, user: user)
    expect(address).to be_valid
  end
end
