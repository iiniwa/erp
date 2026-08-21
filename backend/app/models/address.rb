class Address < ApplicationRecord
  include CodeGeneratable
  include SoftDeletable

  self.primary_key = "address_id"

  belongs_to :address_category,
    foreign_key: :address_category_id, primary_key: :ac_id, inverse_of: :addresses
  belongs_to :user,
    foreign_key: :address_user_code, primary_key: :user_code, optional: true, inverse_of: :addresses
  # No `dependent:` option: addresses are soft-deleted (see SoftDeletable),
  # which never fires Rails' destroy callbacks, so a dependent behavior here
  # would silently never run. The DB foreign keys restrict hard-deleting an
  # address that still has tel/email rows, by design.
  has_many :address_tels, -> { order(:at_sort) },
    foreign_key: :address_id, primary_key: :address_id, inverse_of: :address
  has_many :address_emails, -> { order(:ae_sort) },
    foreign_key: :address_id, primary_key: :address_id, inverse_of: :address

  accepts_nested_attributes_for :address_tels, allow_destroy: true, reject_if: :all_blank
  accepts_nested_attributes_for :address_emails, allow_destroy: true, reject_if: :all_blank

  validates :address_name, :address_ruby, presence: true
  validate :primary_tel_must_be_mobile_for_employee
  validate :only_one_emergency_tel

  before_create :assign_address_id

  private

  def assign_address_id
    self.address_id ||= self.class.generate_code(type_code: "8")
  end

  # Spec section 5.4: an employee's primary (sort=1) contact number is
  # always their mobile number; only enforced for employee-linked addresses
  # (address_user_code present) that actually have a sort=1 tel.
  def primary_tel_must_be_mobile_for_employee
    return unless address_user_code.present?

    primary = address_tels.reject(&:marked_for_destruction?).find { |tel| tel.at_sort == 1 }
    return unless primary
    return if primary.mobile?

    errors.add(:base, "従業員のプライマリ電話番号（並び順1番）は携帯である必要があります")
  end

  # AddressTel's own uniqueness validation only catches a duplicate
  # emergency contact against rows already persisted in the DB; it can't
  # see two brand-new emergency tels submitted together in the same nested
  # request (neither exists yet when each is individually validated), which
  # would otherwise only surface as a raw ActiveRecord::RecordNotUnique at
  # the DB layer. Checking the in-memory collection here catches that case.
  def only_one_emergency_tel
    emergency_tels = address_tels.reject(&:marked_for_destruction?).select(&:emergency?)
    return if emergency_tels.size <= 1

    errors.add(:base, "緊急連絡先は1件までしか登録できません")
  end
end
