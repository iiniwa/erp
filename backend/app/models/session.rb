class Session < ApplicationRecord
  self.primary_key = "session_id"

  belongs_to :user, foreign_key: :user_code, primary_key: :user_code, inverse_of: :sessions

  enum :session_mode, { normal: 1, qr_limited: 2 }, validate: true

  validates :session_token, presence: true, uniqueness: true
  validates :expires_at, presence: true

  scope :active, -> { where("expires_at > ?", Time.current) }
end
