require "rails_helper"

RSpec.describe "Api::V1::PermissionMasters", type: :request do
  let(:admin) { create(:user, user_type: :system_admin, user_must_change_password: false) }
  let(:session_token) do
    _session, raw_token = Session.issue_for(user: admin, mode: :normal)
    raw_token
  end

  describe "GET /api/v1/permission_masters" do
    it "lists permission masters for a system_admin" do
      create(:permission_master, pm_code: "user_manage")

      get "/api/v1/permission_masters", headers: authenticated_headers(session_token)

      expect(response).to have_http_status(:ok)
      expect(json["permission_masters"].map { |pm| pm["pm_code"] }).to include("user_manage")
    end

    it "is forbidden for a non-system_admin, regardless of role_permissions" do
      general_user = create(:user, user_type: :general, user_must_change_password: false)
      _session, token = Session.issue_for(user: general_user, mode: :normal)

      get "/api/v1/permission_masters", headers: authenticated_headers(token)

      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "POST /api/v1/permission_masters" do
    it "creates a permission master and backfills a role_permission row for every existing role" do
      role_a = create(:permission_role)
      role_b = create(:permission_role)

      post "/api/v1/permission_masters", params: { pm_code: "attendance", pm_name: "勤怠管理", pm_sort: 3 },
        headers: authenticated_headers(session_token), as: :json

      expect(response).to have_http_status(:created)
      pm = PermissionMaster.find_by(pm_code: "attendance")
      expect([ role_a.role_id, role_b.role_id ].all? { |id| pm.role_permissions.exists?(role_id: id) }).to be true
    end

    it "is forbidden for a non-system_admin" do
      general_user = create(:user, user_type: :general, user_must_change_password: false)
      _session, token = Session.issue_for(user: general_user, mode: :normal)

      post "/api/v1/permission_masters", params: { pm_code: "attendance", pm_name: "勤怠管理" },
        headers: authenticated_headers(token), as: :json

      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "PATCH /api/v1/permission_masters/:id" do
    it "is forbidden for a non-system_admin" do
      pm = create(:permission_master)
      general_user = create(:user, user_type: :general, user_must_change_password: false)
      _session, token = Session.issue_for(user: general_user, mode: :normal)

      patch "/api/v1/permission_masters/#{pm.pm_id}", params: { pm_name: "改名" },
        headers: authenticated_headers(token), as: :json

      expect(response).to have_http_status(:forbidden)
      expect(pm.reload.pm_name).not_to eq("改名")
    end
  end

  describe "DELETE /api/v1/permission_masters/:id" do
    it "destroys the permission master and its role_permissions" do
      pm = create(:permission_master)
      rp_ids = pm.role_permissions.pluck(:rp_id)

      delete "/api/v1/permission_masters/#{pm.pm_id}", headers: authenticated_headers(session_token)

      expect(response).to have_http_status(:no_content)
      expect(RolePermission.where(rp_id: rp_ids)).to be_empty
    end

    it "is forbidden for a non-system_admin" do
      pm = create(:permission_master)
      general_user = create(:user, user_type: :general, user_must_change_password: false)
      _session, token = Session.issue_for(user: general_user, mode: :normal)

      delete "/api/v1/permission_masters/#{pm.pm_id}", headers: authenticated_headers(token)

      expect(response).to have_http_status(:forbidden)
      expect(PermissionMaster.exists?(pm.pm_id)).to be true
    end
  end

  def json
    JSON.parse(response.body)
  end
end
