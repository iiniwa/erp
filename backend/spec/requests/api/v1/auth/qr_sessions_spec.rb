require "rails_helper"

RSpec.describe "Api::V1::Auth::QrSessions", type: :request do
  let(:user) { create(:user, user_auth_key: "badge-key-123") }

  describe "POST /api/v1/auth/qr_session" do
    it "logs in with a matching auth key and issues a QR-limited session" do
      post "/api/v1/auth/qr_session", params: { auth_key: user.user_auth_key }, headers: internal_api_headers,
        as: :json

      expect(response).to have_http_status(:created)
      expect(json["user"]["user_code"]).to eq(user.user_code)

      session = Session.authenticate(json["session_token"])
      expect(session).to be_qr_limited
    end

    it "rejects an unknown auth key" do
      post "/api/v1/auth/qr_session", params: { auth_key: "no-such-key" }, headers: internal_api_headers, as: :json

      expect(response).to have_http_status(:unauthorized)
    end

    it "rejects a retired user and still counts it as a failed login" do
      retired = create(:user, user_auth_key: "retired-key", user_type: :retired)

      expect do
        post "/api/v1/auth/qr_session", params: { auth_key: retired.user_auth_key }, headers: internal_api_headers,
          as: :json
      end.to change { retired.reload.user_login_fail_count }.by(1)

      expect(response).to have_http_status(:unauthorized)
    end

    it "rejects a locked user" do
      user.lock_account!

      post "/api/v1/auth/qr_session", params: { auth_key: user.user_auth_key }, headers: internal_api_headers,
        as: :json

      expect(response).to have_http_status(:unauthorized)
    end

    it "accumulates onto the same failure counter as password login" do
      retired = create(:user, user_auth_key: "retired-key", user_type: :retired, user_id: "jiro.tanaka")
      retired.password = "himitsu"
      retired.save!

      post "/api/v1/auth/session", params: { identifier: retired.user_id, password: "wrong" },
        headers: internal_api_headers, as: :json
      post "/api/v1/auth/qr_session", params: { auth_key: retired.user_auth_key }, headers: internal_api_headers,
        as: :json

      expect(retired.reload.user_login_fail_count).to eq(2)
    end
  end

  def json
    JSON.parse(response.body)
  end
end
