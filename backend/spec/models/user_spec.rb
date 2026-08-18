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
      CodeSequence.delete_all
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
  end
end
