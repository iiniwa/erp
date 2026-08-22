module PermissionHelper
  # Grants (or overwrites) full/selective access to the given user for a
  # feature, creating the PermissionMaster row and a dedicated PermissionRole
  # (reused across calls for the same user) if they don't exist yet. Request
  # specs for Pundit-gated controllers need this since factories don't go
  # through db/seeds.rb's default grants. Not needed for a system_admin user
  # — that user_type always has full access regardless of role (see
  # ApplicationPolicy).
  def grant_permission!(user, pm_code, view: true, create: true, update: true, delete: true)
    permission_master = PermissionMaster.find_or_create_by!(pm_code: pm_code) { |pm| pm.pm_name = pm_code }

    role = user.permission_role || PermissionRole.create!(role_name: "spec-role-#{SecureRandom.hex(4)}")
    user.update!(role_id: role.role_id) if user.role_id != role.role_id

    role_permission = RolePermission.find_or_create_by!(permission_role: role, permission_master: permission_master)
    role_permission.update!(
      rp_can_view: view, rp_can_create: create, rp_can_update: update, rp_can_delete: delete
    )
    role_permission
  end
end

RSpec.configure do |config|
  config.include PermissionHelper, type: :request
end
