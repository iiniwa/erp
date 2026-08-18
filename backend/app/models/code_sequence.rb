# Backs CodeGeneratable. One row per "type code + year/month" bucket, whose
# last_number is incremented atomically so concurrent callers never receive
# the same number (see docs/ERP_phase1_spec.md section 2).
class CodeSequence < ApplicationRecord
  self.primary_key = "sequence_key"

  validates :sequence_key, presence: true

  # Pessimistic locking (SELECT ... FOR UPDATE) rather than an atomic
  # UPSERT: this table's write volume is tiny (well under 1,000 rows/month
  # across all code types), so a plain row lock is simpler to reason about
  # correctly than relying on MySQL's session-scoped LAST_INSERT_ID()
  # semantics. The rescue/retry handles two callers racing to create the
  # same brand-new key at the same time.
  def self.next_number_for(key)
    transaction do
      row = lock.find_by(sequence_key: key) || create!(sequence_key: key, last_number: 0)
      row.increment!(:last_number)
      row.last_number
    end
  rescue ActiveRecord::RecordNotUnique
    retry
  end
end
