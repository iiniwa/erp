# Generic file registry (spec section 9/10, table `files`). Named
# StoredFile rather than the table's literal "file" to avoid shadowing
# Ruby's own File class throughout the app. SystemSetting's logo/favicon/
# seal fields, and eventually other features, point at rows here via a
# *_file_id column rather than storing SFTPGo paths directly. Deleting a
# StoredFile soft-deletes the DB row only; FileStorageService.delete
# removes the object from SFTPGo separately (see SystemSettingsController).
class StoredFile < ApplicationRecord
  include SoftDeletable

  self.table_name = "files"
  self.primary_key = "file_id"

  belongs_to :uploaded_by_user,
    class_name: "User", foreign_key: :uploaded_by, primary_key: :user_code, optional: true, inverse_of: false

  # Only "general" is reachable this phase (spec section 9.5); "archive"
  # is defined now so FileStorageService's folder routing and this enum
  # don't need to change when t.archive (a later phase) is implemented.
  enum :file_type, { general: 1, archive: 2 }, validate: true

  validates :file_path, :file_name, presence: true
end
