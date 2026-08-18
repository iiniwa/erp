class AddressTel < ApplicationRecord
  self.primary_key = "at_id"

  belongs_to :address, foreign_key: :address_id, primary_key: :address_id, inverse_of: :address_tels

  enum :at_label_type, {
    mobile: 1,
    main: 2,
    fax: 3,
    home: 4,
    emergency: 5,
    free: 6
  }, validate: true

  validates :at_number, presence: true
  validates :at_label_free, presence: true, if: :free?
  # DB-level enforcement (the emergency_slot generated column + unique index
  # in the address_tels migration) is what actually guarantees this under
  # concurrent writes; this validation exists to surface a normal validation
  # error instead of a raw ActiveRecord::RecordNotUnique in the common case.
  validates :address_id, uniqueness: { scope: :at_label_type }, if: :emergency?
  validate :emergency_contact_requires_employee_address

  private

  def emergency_contact_requires_employee_address
    return unless emergency?
    return if address&.address_user_code.present?

    errors.add(:at_label_type, "は従業員本人のアドレスにのみ設定できます")
  end
end
