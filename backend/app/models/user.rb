class User < ApplicationRecord
  include CodeGeneratable
  include SoftDeletable

  self.primary_key = "user_code"

  encrypts :user_auth_key

  enum :user_type, {
    system_admin: 1,
    manager: 2,
    clerical: 3,
    general: 4,
    part_time: 5,
    retired: 9
  }, validate: true

  has_many :addresses, foreign_key: :address_user_code, inverse_of: :user
  has_many :sessions, foreign_key: :user_code, inverse_of: :user

  validates :user_id, uniqueness: true, allow_nil: true
  validates :user_familyname, :user_firstname, :user_familyname_ruby, :user_firstname_ruby, presence: true
  validates :user_pass, presence: true

  before_create :assign_user_code
  before_create :assign_user_entry_date
  before_save :touch_user_update_date

  # Sets user_pass to a bcrypt hash of the given raw password. Named
  # `password=` (not `user_pass=`) so callers don't have to hash it
  # themselves; the column stores the digest directly (see
  # docs/ERP_phase1_spec.md section 5.1 for why it isn't `password_digest`).
  def password=(raw_password)
    self.user_pass = raw_password.present? ? BCrypt::Password.create(raw_password) : nil
  end

  def authenticate_password(raw_password)
    return false if user_pass.blank?

    BCrypt::Password.new(user_pass) == raw_password
  end

  private

  def assign_user_code
    self.user_code ||= self.class.generate_code(type_code: "9")
  end

  def assign_user_entry_date
    self.user_entry_date ||= Date.current
  end

  def touch_user_update_date
    self.user_update_date = Time.current
  end
end
