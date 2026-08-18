class PermissionMaster < ApplicationRecord
  self.primary_key = "pm_id"

  has_many :role_permissions,
    foreign_key: :pm_id, primary_key: :pm_id, dependent: :restrict_with_error, inverse_of: :permission_master

  validates :pm_code, presence: true, uniqueness: true
  validates :pm_name, presence: true

  default_scope { order(:pm_sort) }
end
