# Managing permissions themselves is deliberately not governed by
# t.role_permissions (that would let an admin lock everyone, including
# themselves, out of the one screen that could fix it). Restricted to
# system_admin directly instead.
class PermissionMasterPolicy < ApplicationPolicy
  def index? = user.system_admin?
  def show? = index?
  def create? = user.system_admin?
  def update? = user.system_admin?
  def destroy? = user.system_admin?
end
