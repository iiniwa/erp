class User < ApplicationRecord
  include CodeGeneratable
  include SoftDeletable

  self.primary_key = "user_code"

  # deterministic: true so User.authenticate_by_auth_key can look a scanned
  # QR key up with a plain WHERE equality; Rails' encryption is
  # non-deterministic (random IV per write) by default, which would make
  # that kind of exact-match lookup impossible.
  encrypts :user_auth_key, deterministic: true

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

  before_validation :normalize_user_id
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
    return false if user_is_locked?

    BCrypt::Password.new(user_pass) == raw_password
  end

  # QR and password login share this counter (spec section 3.3).
  def register_failed_login!
    increment!(:user_login_fail_count)
    lock_account! if user_login_fail_count >= SystemSetting.instance.login_lockout_count
  end

  def register_successful_login!
    update!(user_login_fail_count: 0) if user_login_fail_count.positive?
  end

  def lock_account!
    update!(user_is_locked: true)
  end

  # Manual admin action only (spec section 3.3): there is no automatic
  # time-based unlock.
  def unlock_account!
    update!(user_is_locked: false, user_login_fail_count: 0)
  end

  def self.authenticate_by_auth_key(auth_key)
    return nil if auth_key.blank?

    find_by(user_auth_key: auth_key)
  end

  private

  # Blank strings (e.g. an unfilled form field submitted as "") must not
  # reach the uniqueness validation as-is: unlike nil, "" is a normal
  # value, so two employees with no user_id set would otherwise collide
  # on "" instead of both being allowed (validates ... allow_nil: true
  # only exempts actual nil).
  def normalize_user_id
    self.user_id = nil if user_id.blank?
  end

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
