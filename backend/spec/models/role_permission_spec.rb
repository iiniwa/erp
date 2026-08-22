require "rails_helper"

RSpec.describe RolePermission do
  # PermissionMaster#create_role_permissions_for_every_role already
  # creates one row per existing role as soon as the permission_master
  # exists, so the uniqueness constraint is exercised against that
  # auto-created row rather than one this spec creates itself.
  it "requires a unique (role_id, pm_id) pair" do
    role = create(:permission_role)
    permission_master = create(:permission_master)
    duplicate = build(:role_permission, permission_master: permission_master, permission_role: role)

    expect(duplicate).not_to be_valid
  end

  it "allows the same permission_master for a role once its auto-created row is gone" do
    permission_master = create(:permission_master)
    role = create(:permission_role)
    permission_master.role_permissions.where(permission_role: role).delete_all
    other = build(:role_permission, permission_master: permission_master, permission_role: role)

    expect(other).to be_valid
  end
end
