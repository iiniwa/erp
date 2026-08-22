class AddressTel < ApplicationRecord
  self.primary_key = "at_id"

  belongs_to :address, foreign_key: :address_id, primary_key: :address_id, inverse_of: :address_tels

  enum :at_label_type, {
    mobile: 1,
    main: 2,
    fax: 3,
    home: 4,
    free: 5
  }, validate: true

  validates :at_number, presence: true
  validates :at_label_free, presence: true, if: :free?
  # DB-level enforcement (the emergency_slot generated column + unique index
  # in the address_tels migration) is what actually guarantees this under
  # concurrent writes; this validation exists to surface a normal validation
  # error instead of a raw ActiveRecord::RecordNotUnique in the common case.
  # is_emergency is independent of at_label_type (a mobile, home, or
  # free-form number can all serve as the emergency contact).
  #
  # A plain `validates :address_id, uniqueness: { scope: :is_emergency }`
  # queries the DB fresh, which breaks *swapping* the emergency contact in
  # one nested-attributes request: demoting tel A (is_emergency: false)
  # and promoting tel B (is_emergency: true) together would still find
  # A's old, not-yet-persisted `true` value in the DB and reject B as a
  # duplicate. #only_one_emergency_contact_per_address instead accounts
  # for sibling tels' pending (in-memory) state when they're loaded as
  # part of the same Address's nested attributes.
  validate :only_one_emergency_contact_per_address, if: :is_emergency?
  validate :emergency_contact_requires_employee_address

  # Validation alone isn't enough to make a swap safe: accepts_nested_attributes_for
  # saves records in the order they were submitted (address_tels_attributes'
  # order), not by at_sort, so if the *new* emergency contact happens to
  # save before the old one is demoted, its INSERT/UPDATE would transiently
  # collide with the still-`true` old row at the DB level
  # (ActiveRecord::RecordNotUnique on the unique index), even though both
  # records individually passed validation. Clearing any other row's flag
  # immediately before this row's own save removes that order dependency.
  before_save :demote_other_emergency_contacts, if: -> { is_emergency? && will_save_change_to_is_emergency? }

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
  #
  # Only checks whether *any* mobile tel remains, not whether the
  # lowest-sorted survivor is mobile: #promote_next_primary (below) picks
  # the lowest-sorted mobile tel specifically for employee addresses, so a
  # mobile tel at sort=3 is a valid replacement even if a non-mobile tel
  # sits at sort=2.
  def prevent_invalid_employee_primary_removal
    return unless at_sort == 1 && employee_address?

    replacement_exists = self.class.where(address_id: address_id)
      .where.not(at_id: at_id).exists?(at_label_type: :mobile)
    return if replacement_exists

    errors.add(:base, "従業員のプライマリ電話番号（携帯）は他に携帯番号がない限り削除できません")
    throw :abort
  end

  # Spec section 5.5's sort=1-must-exist rule applies here too: if the
  # primary row is removed, promote the next-lowest sort to 1 so a primary
  # always exists. update_column (not update!) skips validations/callbacks
  # since this is a mechanical renumbering, not a user-driven change.
  #
  # For an employee address, promotes the lowest-sorted *mobile* tel
  # specifically (not just the lowest-sorted tel overall) — the two only
  # differ when a non-mobile tel sits between sort=1 and the next mobile
  # tel, e.g. mobile(1)/main(2)/mobile(3): destroying sort=1 should
  # promote the sort=3 mobile, not get stuck on the sort=2 "main" entry.
  # prevent_invalid_employee_primary_removal above already guarantees a
  # mobile candidate exists whenever this runs for an employee address.
  def promote_next_primary
    return unless at_sort == 1

    scope = self.class.where(address_id: address_id)
    next_record = employee_address? ? scope.where(at_label_type: :mobile).order(:at_sort).first : scope.order(:at_sort).first
    next_record&.update_column(:at_sort, 1)
  end

  def employee_address?
    address&.address_user_code.present?
  end

  def emergency_contact_requires_employee_address
    return unless is_emergency?
    return if address&.address_user_code.present?

    errors.add(:is_emergency, "は従業員本人のアドレスにのみ設定できます")
  end

  # Finds other emergency-flagged rows for this address, then excludes
  # any that a sibling object already loaded into address.address_tels
  # (i.e. part of the same nested-attributes submission) is
  # simultaneously demoting to is_emergency: false — that's a swap, not
  # a genuine second emergency contact.
  def only_one_emergency_contact_per_address
    return unless address_id

    conflicting = self.class.where(address_id: address_id, is_emergency: true).where.not(at_id: at_id)
    conflicting = conflicting.reject { |tel| demoted_in_pending_siblings?(tel) }
    return if conflicting.empty?

    errors.add(:base, "緊急連絡先は1件までしか登録できません")
  end

  # A sibling being _destroy'd this same request is no longer a real
  # conflict even if its is_emergency attribute still reads true (nothing
  # marks it false on destruction — it's simply not going to exist
  # afterward).
  def demoted_in_pending_siblings?(persisted_tel)
    return false unless address

    pending_sibling = address.address_tels.find { |tel| tel.at_id == persisted_tel.at_id }
    return false unless pending_sibling

    pending_sibling.marked_for_destruction? || !pending_sibling.is_emergency?
  end

  def demote_other_emergency_contacts
    self.class.where(address_id: address_id, is_emergency: true).where.not(at_id: at_id).update_all(is_emergency: false)
  end
end
