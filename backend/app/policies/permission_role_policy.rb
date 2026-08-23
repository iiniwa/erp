# Mutating roles is restricted to system_admin directly (see
# PermissionMasterPolicy: must never be self-lockable), but merely listing
# role names is not sensitive and is needed by anyone who can create/edit
# an employee, to populate the role-assignment dropdown — so #index/#show
# are open to any authenticated normal-session user rather than gated
# behind system_admin or t.role_permissions.
class PermissionRolePolicy < ApplicationPolicy
  def index? = true
  def show? = index?
  def create? = user.system_admin?
  def update? = user.system_admin?
  def destroy? = user.system_admin?
end
