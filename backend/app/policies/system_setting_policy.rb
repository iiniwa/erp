# Spec section 10.1's "設定画面は管理者権限でのみ編集可能" (only admins can
# edit the settings screen) is treated the same way as
# PermissionMasterPolicy: fixed to system_admin rather than going through
# t.role_permissions, since this configures system-wide infrastructure
# (bank details, tax rate, lockout threshold), not a regular feature.
class SystemSettingPolicy < ApplicationPolicy
  def show? = user.system_admin?
  def update? = user.system_admin?
end
