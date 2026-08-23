# Mirrors frontend/src/lib/validation/phone-number.ts (spec section 445:
# validation rules must stay consistent between the zod schema and the
# backend check). Not an exhaustive Japanese phone number database — area
# code lists run into the hundreds of entries — but a pragmatic ruleset
# covering the shapes that matter here:
#   - mobile / IP phone: 3-4-4 = 11 digits (090/080/070/050-XXXX-XXXX)
#   - freedial / navi-dial: 4-3-3 = 10 digits (0120/0800/0570-XXX-XXX)
#   - landline: variable area-code length, but always 10 digits total
# International numbers (leading "+") are checked more loosely, since
# per-country grouping rules are out of scope here.
module PhoneNumberFormat
  MOBILE = /\A0[5789]0-\d{4}-\d{4}\z/
  FREEDIAL = /\A0(120|800|570)-\d{3}-\d{3}\z/
  LANDLINE = /\A0\d{1,4}-\d{1,4}-\d{4}\z/
  # Deliberately not grouping-strict: unlike Japan's domestic numbers,
  # requiring specific hyphen positions here would reject perfectly valid
  # numbers written without hyphens at all (e.g. "+14155552671"), since
  # per-country grouping conventions vary and are out of scope. Only "+"
  # followed by digits/hyphens, with a digit-count check, matters.
  INTERNATIONAL = /\A\+[\d-]+\z/

  def self.valid?(value)
    return false if value.blank?
    return false if value.include?("(") || value.include?(")")

    return valid_international?(value) if value.start_with?("+")

    return true if MOBILE.match?(value) || FREEDIAL.match?(value)

    LANDLINE.match?(value) && value.delete("-").length == 10
  end

  def self.valid_international?(value)
    return false unless INTERNATIONAL.match?(value)

    value.delete("^0-9").length.between?(8, 15)
  end
  private_class_method :valid_international?
end
