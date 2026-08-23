class PermissionMaster < ApplicationRecord
  self.primary_key = "pm_id"

  # :destroy, not :restrict_with_error: #create_role_permissions_for_every_role
  # below guarantees every PermissionMaster always has a role_permissions row
  # per PermissionRole, so a restrict policy would make every master
  # permanently undeletable. Removing a feature is meant to remove its
  # permission settings along with it.
  has_many :role_permissions,
    foreign_key: :pm_id, primary_key: :pm_id, dependent: :destroy, inverse_of: :permission_master

  validates :pm_code, presence: true, uniqueness: true
  validates :pm_name, presence: true

  default_scope { order(:pm_sort) }

  after_create :create_role_permissions_for_every_role

  private

  # Keeps the settings screen's permission matrix always complete (every
  # role x feature cell has a row to toggle) without having to backfill on
  # read. Defaults to no access; an admin turns rows on from the
  # management screen. Mirrored by PermissionRole#create_role_permissions_for_every_feature
  # for the other direction (a newly created role gets a row for every
  # existing feature).
  def create_role_permissions_for_every_role
    PermissionRole.find_each do |permission_role|
      RolePermission.find_or_create_by!(permission_role: permission_role, permission_master: self)
    end
  end
end
