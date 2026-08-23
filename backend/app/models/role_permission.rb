class RolePermission < ApplicationRecord
  self.primary_key = "rp_id"

  belongs_to :permission_master,
    foreign_key: :pm_id, primary_key: :pm_id, inverse_of: :role_permissions
  belongs_to :permission_role,
    foreign_key: :role_id, primary_key: :role_id, inverse_of: :role_permissions

  validates :pm_id, uniqueness: { scope: :role_id }
end
