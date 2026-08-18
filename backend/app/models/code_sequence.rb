# Backs CodeGeneratable. One row per "type code + year/month" bucket, whose
# last_number is incremented atomically so concurrent callers never receive
# the same number (see docs/ERP_phase1_spec.md section 2).
class CodeSequence < ApplicationRecord
  validates :sequence_key, presence: true, uniqueness: true

  def self.next_number_for(key)
    quoted_key = connection.quote(key)

    connection.execute(<<~SQL.squish)
      INSERT INTO code_sequences (sequence_key, last_number, created_at, updated_at)
      VALUES (#{quoted_key}, 1, NOW(6), NOW(6))
      ON DUPLICATE KEY UPDATE last_number = LAST_INSERT_ID(last_number + 1)
    SQL

    connection.select_value("SELECT LAST_INSERT_ID()").to_i
  end
end
