require "rails_helper"

RSpec.describe "Api::V1::Auth::Passwords", type: :request do
  let(:user) { create(:user, user_must_change_password: true) }

  before do
    user.password = "19900101"
    user.save!
  end

  describe "PATCH /api/v1/auth/password" do
    it "updates the password and clears user_must_change_password" do
      _session, raw_token = Session.issue_for(user: user, mode: :normal)

      patch "/api/v1/auth/password", params: { password: "shinpassword" }, headers: authenticated_headers(raw_token),
        as: :json

      expect(response).to have_http_status(:ok)
      user.reload
      expect(user.user_must_change_password).to be false
      expect(user.authenticate_password("shinpassword")).to be true
    end

    it "is reachable even while user_must_change_password is true (it's the only way out)" do
      _session, raw_token = Session.issue_for(user: user, mode: :normal)

      patch "/api/v1/auth/password", params: { password: "shinpassword" }, headers: authenticated_headers(raw_token),
        as: :json

      expect(response).to have_http_status(:ok)
    end

    it "rejects a password shorter than 4 characters" do
      _session, raw_token = Session.issue_for(user: user, mode: :normal)

      patch "/api/v1/auth/password", params: { password: "abc" }, headers: authenticated_headers(raw_token), as: :json

      expect(response).to have_http_status(:unprocessable_entity)
      expect(user.reload.user_must_change_password).to be true
    end

    it "rejects an unauthenticated request" do
      patch "/api/v1/auth/password", params: { password: "shinpassword" }, headers: internal_api_headers, as: :json

      expect(response).to have_http_status(:unauthorized)
    end
  end
end
