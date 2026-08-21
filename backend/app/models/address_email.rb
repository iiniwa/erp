class AddressEmail < ApplicationRecord
  self.primary_key = "ae_id"

  belongs_to :address,
    foreign_key: :address_id, primary_key: :address_id, inverse_of: :address_emails

  validates :ae_email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }

  after_destroy :promote_next_primary

  private

  # Spec section 5.5: a deleted primary (sort=1) email must be replaced by
  # the next-lowest sort so a primary always exists. update_column (not
  # update!) skips validations/callbacks since this is a mechanical
  # renumbering, not a user-driven change.
  def promote_next_primary
    return unless ae_sort == 1

    next_record = self.class.where(address_id: address_id).order(:ae_sort).first
    next_record&.update_column(:ae_sort, 1)
  end
end
