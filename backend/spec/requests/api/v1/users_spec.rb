require "rails_helper"

RSpec.describe "Api::V1::Users", type: :request do
  let(:admin) { create(:user, user_must_change_password: false) }
  let(:session_token) do
    _session, raw_token = Session.issue_for(user: admin, mode: :normal)
    raw_token
  end

  before { grant_permission!(:general, "user_manage") }

  describe "GET /api/v1/users" do
    it "lists users, excluding soft-deleted ones" do
      active = create(:user)
      deleted = create(:user)
      deleted.soft_delete!

      get "/api/v1/users", headers: authenticated_headers(session_token)

      expect(response).to have_http_status(:ok)
      codes = json["users"].map { |u| u["user_code"] }
      expect(codes).to include(active.user_code)
      expect(codes).not_to include(deleted.user_code)
    end

    it "requires an authenticated session" do
      get "/api/v1/users", headers: internal_api_headers

      expect(response).to have_http_status(:unauthorized)
    end

    it "blocks access while the forced password reset is pending" do
      pending_user = create(:user, user_must_change_password: true)
      _session, token = Session.issue_for(user: pending_user, mode: :normal)

      get "/api/v1/users", headers: authenticated_headers(token)

      expect(response).to have_http_status(:forbidden)
    end

    it "blocks a QR-limited session regardless of role permissions" do
      _session, token = Session.issue_for(user: admin, mode: :qr_limited)

      get "/api/v1/users", headers: authenticated_headers(token)

      expect(response).to have_http_status(:forbidden)
    end

    it "blocks a role with no user_manage permission" do
      no_permission_user = create(:user, user_type: :part_time, user_must_change_password: false)
      _session, token = Session.issue_for(user: no_permission_user, mode: :normal)

      get "/api/v1/users", headers: authenticated_headers(token)

      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "GET /api/v1/users/:user_code" do
    it "returns the employee" do
      employee = create(:user)

      get "/api/v1/users/#{employee.user_code}", headers: authenticated_headers(session_token)

      expect(response).to have_http_status(:ok)
      expect(json["user"]["user_code"]).to eq(employee.user_code)
    end

    it "returns 404 for an unknown user_code" do
      get "/api/v1/users/nonexistent", headers: authenticated_headers(session_token)

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "POST /api/v1/users" do
    let(:valid_params) do
      {
        user_type: "general",
        user_familyname: "山田",
        user_firstname: "太郎",
        user_familyname_ruby: "やまだ",
        user_firstname_ruby: "たろう",
        user_birth: "1995-04-01"
      }
    end

    it "creates an employee with the birthdate as the initial password" do
      post "/api/v1/users", params: valid_params, headers: authenticated_headers(session_token),
        as: :json

      expect(response).to have_http_status(:created)
      created = User.find_by(user_code: json["user"]["user_code"])
      expect(created.authenticate_password("19950401")).to be true
      expect(created.user_must_change_password).to be true
    end

    it "rejects a request without user_birth" do
      post "/api/v1/users", params: valid_params.except(:user_birth),
        headers: authenticated_headers(session_token), as: :json

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "rejects a request missing required profile fields" do
      post "/api/v1/users", params: valid_params.except(:user_familyname),
        headers: authenticated_headers(session_token), as: :json

      expect(response).to have_http_status(:unprocessable_entity)
      expect(json["errors"]).to be_present
    end
  end

  describe "PATCH /api/v1/users/:user_code" do
    it "updates profile fields" do
      employee = create(:user)

      patch "/api/v1/users/#{employee.user_code}", params: { user_firstname: "次郎" },
        headers: authenticated_headers(session_token), as: :json

      expect(response).to have_http_status(:ok)
      expect(employee.reload.user_firstname).to eq("次郎")
    end

    it "allows setting user_id" do
      employee = create(:user, user_id: nil)

      patch "/api/v1/users/#{employee.user_code}", params: { user_id: "jiro.tanaka" },
        headers: authenticated_headers(session_token), as: :json

      expect(response).to have_http_status(:ok)
      expect(employee.reload.user_id).to eq("jiro.tanaka")
    end

    it "rejects a duplicate user_id" do
      create(:user, user_id: "taken")
      employee = create(:user, user_id: nil)

      patch "/api/v1/users/#{employee.user_code}", params: { user_id: "taken" },
        headers: authenticated_headers(session_token), as: :json

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "does not allow changing user_type via the generic update" do
      employee = create(:user, user_type: :general)

      patch "/api/v1/users/#{employee.user_code}", params: { user_type: "system_admin" },
        headers: authenticated_headers(session_token), as: :json

      expect(employee.reload.user_type).to eq("general")
    end
  end

  describe "DELETE /api/v1/users/:user_code" do
    it "soft-deletes the employee" do
      employee = create(:user)

      delete "/api/v1/users/#{employee.user_code}", headers: authenticated_headers(session_token)

      expect(response).to have_http_status(:no_content)
      expect(User.exists?(employee.user_code)).to be false
      expect(User.with_deleted.exists?(employee.user_code)).to be true
    end
  end

  describe "POST /api/v1/users/:user_code/retire" do
    it "sets user_type to retired" do
      employee = create(:user, user_type: :general)

      post "/api/v1/users/#{employee.user_code}/retire",
        headers: authenticated_headers(session_token)

      expect(response).to have_http_status(:ok)
      expect(employee.reload.user_type).to eq("retired")
    end
  end

  def json
    JSON.parse(response.body)
  end
end
