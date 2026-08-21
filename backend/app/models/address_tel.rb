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

  before_destroy :prevent_invalid_employee_primary_removal
  after_destroy :promote_next_primary

  private

  # Direct model-level destroys (e.g. `AddressTel#destroy!` called on its
  # own, outside Address's nested-attributes update) bypass
  # Address#primary_tel_must_be_mobile_for_employee entirely. Without this,
  # destroying an employee's mobile sort=1 tel would succeed and then
  # #promote_next_primary would have to choose between promoting a
  # non-mobile tel (violating spec section 5.4) or leaving no primary at
  # all. Refusing the destroy outright, via `throw(:abort)`, is the
  # correct outcome for either case.
  def prevent_invalid_employee_primary_removal
    return unless at_sort == 1 && employee_address?

    next_record = self.class.where(address_id: address_id).where.not(at_id: at_id).order(:at_sort).first
    return unless next_record && !next_record.mobile?

    errors.add(:base, "従業員のプライマリ電話番号（携帯）は他に携帯番号がない限り削除できません")
    throw :abort
  end

  # Spec section 5.5's sort=1-must-exist rule applies here too: if the
  # primary row is removed, promote the next-lowest sort to 1 so a primary
  # always exists. update_column (not update!) skips validations/callbacks
  # since this is a mechanical renumbering, not a user-driven change.
  def promote_next_primary
    return unless at_sort == 1

    next_record = self.class.where(address_id: address_id).order(:at_sort).first
    next_record&.update_column(:at_sort, 1)
  end

  def employee_address?
    address&.address_user_code.present?
  end

  def emergency_contact_requires_employee_address
    return unless emergency?
    return if address&.address_user_code.present?

    errors.add(:at_label_type, "は従業員本人のアドレスにのみ設定できます")
  end
end
