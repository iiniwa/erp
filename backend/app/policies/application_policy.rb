# Spec section 4: authorization is data-driven (t.role_permissions), not
# role-hardcoded in Ruby. Subclasses only declare which pm_code (spec
# section 5.7's t.permission_master.pm_code) they gate.
#
# system_admin (the fixed employment classification, not a PermissionRole)
# always has full access regardless of role_id assignment: it is the one
# account that can manage roles/permissions themselves, so its own access
# to every other RBAC-governed feature must never depend on a role that an
# admin could misconfigure or delete out from under it.
class ApplicationPolicy
  attr_reader :user, :record

  def initialize(user, record)
    @user = user
    @record = record
  end

  def index? = user.system_admin? || (permission&.rp_can_view || false)
  def show? = index?
  def create? = user.system_admin? || (permission&.rp_can_create || false)
  def update? = user.system_admin? || (permission&.rp_can_update || false)
  def destroy? = user.system_admin? || (permission&.rp_can_delete || false)

  private

  # Subclasses set this to the pm_code their controller corresponds to
  # (e.g. "user_manage", "address_book").
  def pm_code
    raise NotImplementedError, "#{self.class} must implement #pm_code"
  end

  def permission
    return @permission if defined?(@permission)

    @permission = user.role_id && RolePermission
      .joins(:permission_master)
      .find_by(role_id: user.role_id, permission_masters: { pm_code: pm_code })
  end
end
