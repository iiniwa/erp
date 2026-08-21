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

  describe "primary tel must be mobile for employee addresses" do
    it "rejects an employee address whose sort=1 tel is not mobile" do
      user = create(:user)
      address = build(:address, user: user)
      address.address_tels.build(at_number: "0311112222", at_label_type: :main, at_sort: 1)

      expect(address).not_to be_valid
    end

    it "accepts an employee address whose sort=1 tel is mobile" do
      user = create(:user)
      address = build(:address, user: user)
      address.address_tels.build(at_number: "09000000000", at_label_type: :mobile, at_sort: 1)

      expect(address).to be_valid
    end

    it "does not enforce the mobile rule for non-employee addresses" do
      address = build(:address, user: nil)
      address.address_tels.build(at_number: "0311112222", at_label_type: :main, at_sort: 1)

      expect(address).to be_valid
    end
  end
end
