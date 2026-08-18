require "rails_helper"

RSpec.describe RolePermission do
  it "requires a unique (rp_user_type, pm_id) pair" do
    permission_master = create(:permission_master)
    create(:role_permission, permission_master: permission_master, rp_user_type: :general)
    duplicate = build(:role_permission, permission_master: permission_master, rp_user_type: :general)

    expect(duplicate).not_to be_valid
  end

  it "allows the same permission_master for different user types" do
    permission_master = create(:permission_master)
    create(:role_permission, permission_master: permission_master, rp_user_type: :general)
    other = build(:role_permission, permission_master: permission_master, rp_user_type: :manager)

    expect(other).to be_valid
  end
end
