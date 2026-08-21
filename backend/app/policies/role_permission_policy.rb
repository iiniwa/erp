# See PermissionMasterPolicy: kept off the data-driven RBAC table for the
# same reason (must never be self-lockable).
class RolePermissionPolicy < ApplicationPolicy
  def index? = user.system_admin?
  def show? = index?
  def create? = user.system_admin?
  def update? = user.system_admin?
  def destroy? = user.system_admin?
end
