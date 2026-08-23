# Freely admin-creatable/deletable permission level (spec section 4):
# unlike User#user_type (a fixed employment classification), roles here
# are an open set an admin manages from the settings screen and assigns
# to employees independently of their employment type.
class PermissionRole < ApplicationRecord
  self.primary_key = "role_id"

  has_many :role_permissions, foreign_key: :role_id, primary_key: :role_id,
    dependent: :destroy, inverse_of: :permission_role
  has_many :users, foreign_key: :role_id, primary_key: :role_id, inverse_of: :permission_role,
    dependent: :nullify

  validates :role_name, presence: true, uniqueness: true

  default_scope { order(:role_sort) }

  after_create :create_role_permissions_for_every_feature

  private

  # Mirrors PermissionMaster#create_role_permissions_for_every_feature:
  # keeps the permission matrix always complete in both directions, so a
  # newly created role immediately has an editable (default no-access) row
  # for every existing feature.
  def create_role_permissions_for_every_feature
    PermissionMaster.find_each do |permission_master|
      RolePermission.find_or_create_by!(permission_role: self, permission_master: permission_master)
    end
  end
end
