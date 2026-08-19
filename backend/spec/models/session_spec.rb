require "rails_helper"

RSpec.describe Session do
  it "requires a unique session_token" do
    create(:session, session_token: "abc123")
    duplicate = build(:session, session_token: "abc123")

    expect(duplicate).not_to be_valid
  end

  describe ".active" do
    it "excludes expired sessions" do
      expired = create(:session, expires_at: 1.hour.ago)
      active = create(:session, expires_at: 1.hour.from_now)

      expect(described_class.active).to include(active)
      expect(described_class.active).not_to include(expired)
    end
  end
end
