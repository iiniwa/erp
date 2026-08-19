class RolePermission < ApplicationRecord
  self.primary_key = "rp_id"

  belongs_to :permission_master,
    foreign_key: :pm_id, primary_key: :pm_id, inverse_of: :role_permissions

  enum :rp_user_type, {
    system_admin: 1,
    manager: 2,
    clerical: 3,
    general: 4,
    part_time: 5,
    retired: 9
  }, validate: true

  validates :pm_id, uniqueness: { scope: :rp_user_type }
end
