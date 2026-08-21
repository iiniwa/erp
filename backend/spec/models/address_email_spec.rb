require "rails_helper"

RSpec.describe AddressEmail do
  it "requires a validly formatted email address" do
    email = build(:address_email, ae_email: "not-an-email")
    expect(email).not_to be_valid
  end

  it "allows a NULL label" do
    email = build(:address_email, ae_label: nil)
    expect(email).to be_valid
  end

  describe "primary promotion on destroy" do
    it "promotes the next-lowest sort to 1 when the primary is destroyed" do
      address = create(:address)
      primary = create(:address_email, address: address, ae_sort: 1)
      secondary = create(:address_email, address: address, ae_sort: 2)

      primary.destroy!

      expect(secondary.reload.ae_sort).to eq(1)
    end

    it "does not touch sort ordering when a non-primary is destroyed" do
      address = create(:address)
      create(:address_email, address: address, ae_sort: 1)
      secondary = create(:address_email, address: address, ae_sort: 2)

      secondary.destroy!

      expect(AddressEmail.where(address_id: address.address_id).count).to eq(1)
    end
  end
end
