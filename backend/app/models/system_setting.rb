# Maps to the `systems` table (t.system in the spec), a singleton table that
# always holds exactly one row (system_id = 1). Use `SystemSetting.instance`
# to fetch or build that row rather than `.new`/`.create` directly.
class SystemSetting < ApplicationRecord
  self.table_name = "systems"
  self.primary_key = "system_id"

  belongs_to :updated_by_user,
    class_name: "User", foreign_key: :updated_by, primary_key: :user_code, optional: true, inverse_of: false

  enum :bank_account_type, { ordinary: 1, checking: 2 }, validate: { allow_nil: true }

  validates :system_id, inclusion: { in: [ 1 ] }

  # find_or_initialize_by sets system_id: 1 on a freshly built record, so
  # callers never need to (and, per the validation above, aren't allowed to
  # set it to anything else).
  def self.instance
    find_or_initialize_by(system_id: 1)
  end
end
