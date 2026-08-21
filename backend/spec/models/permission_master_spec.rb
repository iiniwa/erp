require "rails_helper"

RSpec.describe PermissionMaster do
  it "requires a unique pm_code" do
    create(:permission_master, pm_code: "user_manage")
    duplicate = build(:permission_master, pm_code: "user_manage")

    expect(duplicate).not_to be_valid
  end

  it "backfills a no-access role_permission row for every user_type on create" do
    pm = create(:permission_master)

    expect(pm.role_permissions.pluck(:rp_user_type)).to match_array(RolePermission.rp_user_types.keys)
    expect(pm.role_permissions).to all(
      have_attributes(rp_can_view: false, rp_can_create: false, rp_can_update: false, rp_can_delete: false)
    )
  end

  it "destroys its role_permissions when destroyed" do
    pm = create(:permission_master)
    rp_ids = pm.role_permissions.pluck(:rp_id)

    pm.destroy!

    expect(RolePermission.where(rp_id: rp_ids)).to be_empty
  end
end
