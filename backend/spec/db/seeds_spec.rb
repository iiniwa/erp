require "rails_helper"

RSpec.describe "db/seeds.rb" do
  it "creates the fixed system administrator on first run" do
    expect { load Rails.root.join("db/seeds.rb") }.to change(User, :count).by(1)

    admin = User.system_admin.sole
    expect(admin.user_id).to be_nil
    expect(admin.user_must_change_password).to be true
    expect(admin.authenticate_password(admin.user_birth.strftime("%Y%m%d"))).to be true

    address = admin.addresses.sole
    expect(address.address_tels.sole).to be_mobile
  end

  it "is idempotent" do
    load Rails.root.join("db/seeds.rb")

    expect { load Rails.root.join("db/seeds.rb") }.not_to change(User, :count)
  end
end
