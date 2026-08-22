require "rails_helper"

RSpec.describe PermissionMaster do
  it "requires a unique pm_code" do
    create(:permission_master, pm_code: "user_manage")
    duplicate = build(:permission_master, pm_code: "user_manage")

    expect(duplicate).not_to be_valid
  end

  it "backfills a no-access role_permission row for every existing role on create" do
    role_a = create(:permission_role)
    role_b = create(:permission_role)

    pm = create(:permission_master)

    expect(pm.role_permissions.pluck(:role_id)).to match_array([ role_a.role_id, role_b.role_id ])
    expect(pm.role_permissions).to all(
      have_attributes(rp_can_view: false, rp_can_create: false, rp_can_update: false, rp_can_delete: false)
    )
  end

  it "destroys its role_permissions when destroyed" do
    create(:permission_role)
    pm = create(:permission_master)
    rp_ids = pm.role_permissions.pluck(:rp_id)

    pm.destroy!

    expect(RolePermission.where(rp_id: rp_ids)).to be_empty
  end
end
