require "rails_helper"

RSpec.describe RolePermission do
  # PermissionMaster#create_role_permissions_for_every_user_type already
  # creates one row per user_type as soon as the permission_master exists,
  # so the uniqueness constraint is exercised against that auto-created
  # row rather than one this spec creates itself.
  it "requires a unique (rp_user_type, pm_id) pair" do
    permission_master = create(:permission_master)
    duplicate = build(:role_permission, permission_master: permission_master, rp_user_type: :general)

    expect(duplicate).not_to be_valid
  end

  it "allows the same permission_master for different user types" do
    permission_master = create(:permission_master)
    permission_master.role_permissions.where(rp_user_type: :manager).delete_all
    other = build(:role_permission, permission_master: permission_master, rp_user_type: :manager)

    expect(other).to be_valid
  end
end
