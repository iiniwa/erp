# Backs CodeGeneratable. One row per "type code + year/month" bucket, whose
# last_number is incremented atomically so concurrent callers never receive
# the same number (see docs/ERP_phase1_spec.md section 2).
class CodeSequence < ApplicationRecord
  self.primary_key = "sequence_key"

  validates :sequence_key, presence: true

  def self.next_number_for(key)
    quoted_key = connection.quote(key)

    # LAST_INSERT_ID(1) on the fresh-row branch is required, not decorative:
    # a plain `VALUES (..., 1, ...)` would leave the session's
    # LAST_INSERT_ID() at whatever an unrelated prior statement set it to,
    # since this table has no AUTO_INCREMENT column of its own to trigger it.
    connection.execute(<<~SQL.squish)
      INSERT INTO code_sequences (sequence_key, last_number, created_at, updated_at)
      VALUES (#{quoted_key}, LAST_INSERT_ID(1), NOW(6), NOW(6))
      ON DUPLICATE KEY UPDATE last_number = LAST_INSERT_ID(last_number + 1)
    SQL

    connection.select_value("SELECT LAST_INSERT_ID()").to_i
  end
end
