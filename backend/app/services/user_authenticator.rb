# Resolves the login identifier (user_id or primary mobile number, spec
# section 3.1) and password into a User, applying the lockout policy from
# SystemSetting#login_lockout_count.
class UserAuthenticator
  Result = Struct.new(:user, :error, keyword_init: true) do
    def success?
      user.present?
    end
  end

  def self.call(...)
    new(...).call
  end

  def initialize(identifier:, password:)
    @identifier = identifier
    @password = password
  end

  def call
    user = find_user
    return Result.new(error: :invalid_credentials) unless user
    return Result.new(error: :account_locked) if user.user_is_locked?

    if user.authenticate_password(@password)
      user.register_successful_login!
      Result.new(user: user)
    else
      user.register_failed_login!
      Result.new(error: :invalid_credentials)
    end
  end

  private

  def find_user
    return nil if @identifier.blank?

    User.find_by(user_id: @identifier) || find_by_primary_mobile_number(@identifier)
  end

  # Only the primary (at_sort = 1) mobile number of the address book entry
  # linked back to a user (address_user_code) counts as a login identifier
  # (spec section 3.1).
  def find_by_primary_mobile_number(phone_number)
    address_tel = AddressTel
      .joins(:address)
      .where(at_number: phone_number, at_sort: 1, at_label_type: AddressTel.at_label_types[:mobile])
      .where.not(addresses: { address_user_code: nil })
      .first

    return nil unless address_tel

    User.find_by(user_code: address_tel.address.address_user_code)
  end
end
