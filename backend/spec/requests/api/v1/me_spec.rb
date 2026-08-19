require "rails_helper"

RSpec.describe "Api::V1::Me", type: :request do
  describe "GET /api/v1/me" do
    it "returns the current user when the password reset is already done" do
      user = create(:user, user_must_change_password: false)
      _session, raw_token = Session.issue_for(user: user, mode: :normal)

      get "/api/v1/me", headers: authenticated_headers(raw_token)

      expect(response).to have_http_status(:ok)
      expect(json["user"]["user_code"]).to eq(user.user_code)
    end

    it "blocks access until the forced first-login password reset is done" do
      user = create(:user, user_must_change_password: true)
      _session, raw_token = Session.issue_for(user: user, mode: :normal)

      get "/api/v1/me", headers: authenticated_headers(raw_token)

      expect(response).to have_http_status(:forbidden)
      expect(json["error"]).to eq("password_reset_required")
    end

    it "rejects a request without a valid session" do
      get "/api/v1/me", headers: internal_api_headers

      expect(response).to have_http_status(:unauthorized)
    end
  end

  def json
    JSON.parse(response.body)
  end
end
