class Session < ApplicationRecord
  self.primary_key = "session_id"

  DEFAULT_TTL = 12.hours

  belongs_to :user, foreign_key: :user_code, primary_key: :user_code, inverse_of: :sessions

  enum :session_mode, { normal: 1, qr_limited: 2 }, validate: true

  validates :session_token, presence: true, uniqueness: true
  validates :expires_at, presence: true

  scope :active, -> { where("expires_at > ?", Time.current) }

  # session_token stores a hash rather than the raw token (spec section
  # 5.6), so a stolen DB row can't be replayed as a session cookie. Returns
  # [session, raw_token]; only the raw_token is safe to hand to the client.
  def self.issue_for(user:, mode:, ip_address: nil, user_agent: nil, ttl: DEFAULT_TTL)
    raw_token = SecureRandom.hex(32)
    session = create!(
      user: user,
      session_token: hash_token(raw_token),
      session_mode: mode,
      ip_address: ip_address,
      user_agent: user_agent,
      expires_at: Time.current + ttl
    )
    [ session, raw_token ]
  end

  def self.authenticate(raw_token)
    return nil if raw_token.blank?

    active.find_by(session_token: hash_token(raw_token))
  end

  def self.hash_token(raw_token)
    Digest::SHA256.hexdigest(raw_token)
  end
end
