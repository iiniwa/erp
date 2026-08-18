class AddressEmail < ApplicationRecord
  self.primary_key = "ae_id"

  belongs_to :address,
    foreign_key: :address_id, primary_key: :address_id, inverse_of: :address_emails

  validates :ae_email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
end
