require "rails_helper"

RSpec.describe User do
  subject { create(:user) }

  it_behaves_like "a soft-deletable model"

  describe "user_code generation" do
    it "assigns a code formatted as 9YYMMNNN on create" do
      travel_to Time.zone.local(2026, 8, 19, 12, 0, 0) do
        user = create(:user)
        expect(user.user_code).to match(/\A9\d{7}\z/)
        expect(user.user_code).to start_with("92608")
      end
    end

    it "never issues the same user_code under concurrent creation", use_transactional_tests: false do
      thread_count = 20
      users = Array.new(thread_count)
      sequence_key = "9-#{Time.current.strftime('%y%m')}"

      # Rails.application.executor.wrap sets up the per-thread execution
      # context ActiveRecord needs (connection checkout/checkin, error
      # reporting, etc.) for code running on ad-hoc threads outside the
      # normal request/example cycle; without it, threads can end up
      # fighting over a single connection.
      threads = Array.new(thread_count) do |i|
        Thread.new do
          Rails.application.executor.wrap do
            users[i] = create(:user)
          end
        end
      end
      threads.each(&:join)

      expect(users.map(&:user_code).uniq.length).to eq(thread_count)
    ensure
      User.delete_all
      CodeSequence.where(sequence_key: sequence_key).delete_all
    end
  end

  describe "#password=" do
    it "stores a bcrypt hash rather than the raw password" do
      user = build(:user)
      user.password = "himitsu"

      expect(user.user_pass).not_to eq("himitsu")
      expect(user.authenticate_password("himitsu")).to be true
      expect(user.authenticate_password("wrong")).to be false
    end

    it "rejects the correct password once the account is locked" do
      user = build(:user, user_is_locked: true)
      user.password = "himitsu"

      expect(user.authenticate_password("himitsu")).to be false
    end
  end

  describe "single system_admin validation" do
    it "rejects creating a second system_admin" do
      create(:user, user_type: :system_admin)
      duplicate = build(:user, user_type: :system_admin)

      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:base]).to be_present
    end

    it "rejects even against a soft-deleted system_admin" do
      admin = create(:user, user_type: :system_admin)
      admin.soft_delete!
      duplicate = build(:user, user_type: :system_admin)

      expect(duplicate).not_to be_valid
    end

    it "allows re-saving the existing system_admin" do
      admin = create(:user, user_type: :system_admin)

      expect(admin).to be_valid
    end

    it "allows non-system_admin user_types freely" do
      create(:user, user_type: :general)
      other = build(:user, user_type: :general)

      expect(other).to be_valid
    end
  end

  describe "user_id uniqueness" do
    it "allows multiple users with a NULL user_id" do
      create(:user, user_id: nil)
      second = build(:user, user_id: nil)

      expect(second).to be_valid
    end

    it "rejects a duplicate non-NULL user_id" do
      create(:user, user_id: "taro.yamada")
      duplicate = build(:user, user_id: "taro.yamada")

      expect(duplicate).not_to be_valid
    end

    it "allows multiple users with a blank string user_id (normalized to NULL)" do
      create(:user, user_id: "")
      second = build(:user, user_id: "")

      expect(second).to be_valid
      expect(second.user_id).to be_nil
    end
  end

  describe "lockout" do
    it "locks the account once user_login_fail_count reaches login_lockout_count" do
      user = create(:user)
      SystemSetting.instance.update!(login_lockout_count: 2)

      user.register_failed_login!
      expect(user.user_is_locked).to be false

      user.register_failed_login!
      expect(user.user_is_locked).to be true
    end

    it "resets the counter on a successful login" do
      user = create(:user, user_login_fail_count: 3)

      user.register_successful_login!

      expect(user.user_login_fail_count).to eq(0)
    end

    it "unlocks the account and resets the counter" do
      user = create(:user, user_is_locked: true, user_login_fail_count: 10)

      user.unlock_account!

      expect(user.user_is_locked).to be false
      expect(user.user_login_fail_count).to eq(0)
    end
  end

  describe ".authenticate_by_auth_key" do
    it "finds the user with a matching auth key" do
      user = create(:user, user_auth_key: "badge-123")

      expect(described_class.authenticate_by_auth_key("badge-123")).to eq(user)
    end

    it "returns nil for a non-matching key" do
      create(:user, user_auth_key: "badge-123")

      expect(described_class.authenticate_by_auth_key("badge-999")).to be_nil
    end

    it "stores the auth key encrypted, not in plaintext" do
      user = create(:user, user_auth_key: "badge-123")

      raw_column_value = described_class.connection.select_value(
        "SELECT user_auth_key FROM users WHERE user_code = #{described_class.connection.quote(user.user_code)}"
      )
      expect(raw_column_value).not_to eq("badge-123")
    end
  end
end
