module PermissionHelper
  # Grants (or overwrites) full/selective access for a user_type on a
  # feature, creating the PermissionMaster row if it doesn't exist yet.
  # Request specs for Pundit-gated controllers need this since factories
  # don't go through db/seeds.rb's default grants.
  def grant_permission!(user_type, pm_code, view: true, create: true, update: true, delete: true)
    permission_master = PermissionMaster.find_or_create_by!(pm_code: pm_code) { |pm| pm.pm_name = pm_code }
    role_permission = RolePermission.find_or_create_by!(rp_user_type: user_type, permission_master: permission_master)
    role_permission.update!(
      rp_can_view: view, rp_can_create: create, rp_can_update: update, rp_can_delete: delete
    )
    role_permission
  end
end

RSpec.configure do |config|
  config.include PermissionHelper, type: :request
end
