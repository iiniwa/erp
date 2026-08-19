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

  describe ".issue_for / .authenticate" do
    it "authenticates the raw token issue_for returns" do
      user = create(:user)

      session, raw_token = described_class.issue_for(user: user, mode: :normal)

      expect(described_class.authenticate(raw_token)).to eq(session)
    end

    it "does not store the raw token in the database" do
      user = create(:user)

      _session, raw_token = described_class.issue_for(user: user, mode: :normal)

      expect(described_class.find_by(session_token: raw_token)).to be_nil
    end

    it "does not authenticate an expired session" do
      user = create(:user)

      _session, raw_token = described_class.issue_for(user: user, mode: :normal, ttl: -1.minute)

      expect(described_class.authenticate(raw_token)).to be_nil
    end

    it "does not authenticate a blank token" do
      expect(described_class.authenticate(nil)).to be_nil
      expect(described_class.authenticate("")).to be_nil
    end
  end
end
