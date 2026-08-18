# Generates TTYYMMNNN-style codes per docs/ERP_phase1_spec.md section 2:
# a type code, the current year/month, and a zero-padded sequence number
# that resets every month. Concurrency safety is delegated to CodeSequence,
# which relies on an atomic UPSERT rather than an explicit row lock.
module CodeGeneratable
  extend ActiveSupport::Concern

  class_methods do
    def generate_code(type_code:, digits: 3, at: Time.current)
      year_month = at.strftime("%y%m")
      key = "#{type_code}-#{year_month}"
      number = CodeSequence.next_number_for(key)

      "#{type_code}#{year_month}#{number.to_s.rjust(digits, "0")}"
    end
  end
end
