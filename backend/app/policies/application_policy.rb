# Spec section 4: authorization is data-driven (t.role_permissions), not
# role-hardcoded in Ruby. Subclasses only declare which pm_code (spec
# section 5.7's t.permission_master.pm_code) they gate.
class ApplicationPolicy
  attr_reader :user, :record

  def initialize(user, record)
    @user = user
    @record = record
  end

  def index? = permission&.rp_can_view || false
  def show? = index?
  def create? = permission&.rp_can_create || false
  def update? = permission&.rp_can_update || false
  def destroy? = permission&.rp_can_delete || false

  private

  # Subclasses set this to the pm_code their controller corresponds to
  # (e.g. "user_manage", "address_book").
  def pm_code
    raise NotImplementedError, "#{self.class} must implement #pm_code"
  end

  def permission
    return @permission if defined?(@permission)

    @permission = RolePermission
      .joins(:permission_master)
      .find_by(rp_user_type: user.user_type, permission_masters: { pm_code: pm_code })
  end
end
