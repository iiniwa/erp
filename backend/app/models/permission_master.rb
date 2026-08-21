class PermissionMaster < ApplicationRecord
  self.primary_key = "pm_id"

  # :destroy, not :restrict_with_error: #create_role_permissions_for_every_user_type
  # below guarantees every PermissionMaster always has a role_permissions row per
  # user_type, so a restrict policy would make every master permanently
  # undeletable. Removing a feature is meant to remove its permission
  # settings along with it.
  has_many :role_permissions,
    foreign_key: :pm_id, primary_key: :pm_id, dependent: :destroy, inverse_of: :permission_master

  validates :pm_code, presence: true, uniqueness: true
  validates :pm_name, presence: true

  default_scope { order(:pm_sort) }

  after_create :create_role_permissions_for_every_user_type

  private

  # Keeps the settings screen's permission matrix always complete (every
  # user_type x feature cell has a row to toggle) without having to
  # backfill on read. Defaults to no access; an admin turns rows on from
  # the management screen. Also how the retired user_type (spec section 4)
  # ends up with an explicit, editable row instead of implicitly "no row
  # means no access".
  def create_role_permissions_for_every_user_type
    RolePermission.rp_user_types.each_key do |user_type|
      RolePermission.find_or_create_by!(rp_user_type: user_type, permission_master: self)
    end
  end
end
