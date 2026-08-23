require "rails_helper"

RSpec.describe PermissionRole do
  it "requires a unique role_name" do
    create(:permission_role, role_name: "スタッフ")
    duplicate = build(:permission_role, role_name: "スタッフ")

    expect(duplicate).not_to be_valid
  end

  it "backfills a no-access role_permission row for every existing feature on create" do
    pm_a = create(:permission_master)
    pm_b = create(:permission_master)

    role = create(:permission_role)

    expect(role.role_permissions.pluck(:pm_id)).to match_array([ pm_a.pm_id, pm_b.pm_id ])
    expect(role.role_permissions).to all(
      have_attributes(rp_can_view: false, rp_can_create: false, rp_can_update: false, rp_can_delete: false)
    )
  end

  it "destroys its role_permissions when destroyed" do
    create(:permission_master)
    role = create(:permission_role)
    rp_ids = role.role_permissions.pluck(:rp_id)

    role.destroy!

    expect(RolePermission.where(rp_id: rp_ids)).to be_empty
  end

  it "nullifies role_id on assigned users when destroyed" do
    role = create(:permission_role)
    user = create(:user, role_id: role.role_id)

    role.destroy!

    expect(user.reload.role_id).to be_nil
  end
end
