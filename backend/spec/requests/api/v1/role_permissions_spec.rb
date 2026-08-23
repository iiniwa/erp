require "rails_helper"

RSpec.describe "Api::V1::RolePermissions", type: :request do
  let(:admin) { create(:user, user_type: :system_admin, user_must_change_password: false) }
  let(:session_token) do
    _session, raw_token = Session.issue_for(user: admin, mode: :normal)
    raw_token
  end

  describe "GET /api/v1/role_permissions" do
    it "lists the full matrix for a system_admin" do
      role_a = create(:permission_role)
      role_b = create(:permission_role)
      create(:permission_master, pm_code: "user_manage")

      get "/api/v1/role_permissions", headers: authenticated_headers(session_token)

      expect(response).to have_http_status(:ok)
      role_ids = json["role_permissions"].select { |rp| rp["pm_code"] == "user_manage" }.map { |rp| rp["role_id"] }
      expect(role_ids).to match_array([ role_a.role_id, role_b.role_id ])
    end

    it "is forbidden for a non-system_admin" do
      general_user = create(:user, user_type: :general, user_must_change_password: false)
      _session, token = Session.issue_for(user: general_user, mode: :normal)

      get "/api/v1/role_permissions", headers: authenticated_headers(token)

      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "PATCH /api/v1/role_permissions/:id" do
    it "updates the access flags for one role x feature cell" do
      role = create(:permission_role)
      permission_master = create(:permission_master, pm_code: "address_book")
      role_permission = permission_master.role_permissions.find_by(permission_role: role)

      patch "/api/v1/role_permissions/#{role_permission.rp_id}",
        params: { rp_can_view: true, rp_can_create: true },
        headers: authenticated_headers(session_token), as: :json

      expect(response).to have_http_status(:ok)
      expect(role_permission.reload.rp_can_view).to be true
      expect(role_permission.rp_can_create).to be true
      expect(role_permission.rp_can_delete).to be false
    end

    it "is forbidden for a non-system_admin" do
      role = create(:permission_role)
      permission_master = create(:permission_master, pm_code: "address_book")
      role_permission = permission_master.role_permissions.find_by(permission_role: role)
      general_user = create(:user, user_type: :general, user_must_change_password: false)
      _session, token = Session.issue_for(user: general_user, mode: :normal)

      patch "/api/v1/role_permissions/#{role_permission.rp_id}", params: { rp_can_view: true },
        headers: authenticated_headers(token), as: :json

      expect(response).to have_http_status(:forbidden)
      expect(role_permission.reload.rp_can_view).to be false
    end
  end

  def json
    JSON.parse(response.body)
  end
end
