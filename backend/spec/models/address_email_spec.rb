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
end
