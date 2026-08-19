require "rails_helper"

RSpec.describe "Api::V1::Auth::Sessions", type: :request do
  let(:user) { create(:user, user_id: "taro.yamada") }
  let!(:address) { create(:address, user: user) }
  let!(:primary_tel) { create(:address_tel, address: address) }

  before do
    user.password = "himitsu"
    user.save!
  end

  describe "POST /api/v1/auth/session" do
    it "logs in with the user_id and password" do
      post "/api/v1/auth/session", params: { identifier: user.user_id, password: "himitsu" },
        headers: internal_api_headers, as: :json

      expect(response).to have_http_status(:created)
      expect(json["session_token"]).to be_present
      expect(json["user"]["user_code"]).to eq(user.user_code)
    end

    it "logs in with the primary mobile number and password" do
      post "/api/v1/auth/session", params: { identifier: primary_tel.at_number, password: "himitsu" },
        headers: internal_api_headers, as: :json

      expect(response).to have_http_status(:created)
      expect(json["user"]["user_code"]).to eq(user.user_code)
    end

    it "rejects an unknown identifier" do
      post "/api/v1/auth/session", params: { identifier: "nobody", password: "himitsu" },
        headers: internal_api_headers, as: :json

      expect(response).to have_http_status(:unauthorized)
    end

    it "rejects the wrong password and increments the failure counter" do
      expect do
        post "/api/v1/auth/session", params: { identifier: user.user_id, password: "wrong" },
          headers: internal_api_headers, as: :json
      end.to change { user.reload.user_login_fail_count }.by(1)

      expect(response).to have_http_status(:unauthorized)
    end

    it "locks the account once login_lockout_count is reached" do
      SystemSetting.instance.update!(login_lockout_count: 3)

      3.times do
        post "/api/v1/auth/session", params: { identifier: user.user_id, password: "wrong" },
          headers: internal_api_headers, as: :json
      end

      expect(user.reload.user_is_locked).to be true

      post "/api/v1/auth/session", params: { identifier: user.user_id, password: "himitsu" },
        headers: internal_api_headers, as: :json

      expect(response).to have_http_status(:unauthorized)
      expect(json["error"]).to eq("account_locked")
    end

    it "resets the failure counter after a successful login" do
      post "/api/v1/auth/session", params: { identifier: user.user_id, password: "wrong" },
        headers: internal_api_headers, as: :json
      post "/api/v1/auth/session", params: { identifier: user.user_id, password: "himitsu" },
        headers: internal_api_headers, as: :json

      expect(user.reload.user_login_fail_count).to eq(0)
    end

    it "rejects requests without the internal API secret" do
      post "/api/v1/auth/session", params: { identifier: user.user_id, password: "himitsu" }, as: :json

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "GET /api/v1/auth/session" do
    it "returns the current user for a valid session token" do
      session, raw_token = Session.issue_for(user: user, mode: :normal)

      get "/api/v1/auth/session", headers: authenticated_headers(raw_token)

      expect(response).to have_http_status(:ok)
      expect(json["user"]["user_code"]).to eq(user.user_code)
      expect(json["session_mode"]).to eq(session.session_mode)
    end

    it "rejects a missing or invalid token" do
      get "/api/v1/auth/session", headers: authenticated_headers("not-a-real-token")

      expect(response).to have_http_status(:unauthorized)
    end

    it "rejects an expired session" do
      _session, raw_token = Session.issue_for(user: user, mode: :normal, ttl: -1.minute)

      get "/api/v1/auth/session", headers: authenticated_headers(raw_token)

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "DELETE /api/v1/auth/session" do
    it "deletes the session so the token can no longer be used" do
      _session, raw_token = Session.issue_for(user: user, mode: :normal)

      delete "/api/v1/auth/session", headers: authenticated_headers(raw_token)
      expect(response).to have_http_status(:no_content)

      get "/api/v1/auth/session", headers: authenticated_headers(raw_token)
      expect(response).to have_http_status(:unauthorized)
    end
  end

  def json
    JSON.parse(response.body)
  end
end
