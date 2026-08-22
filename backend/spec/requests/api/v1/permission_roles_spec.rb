require "rails_helper"

RSpec.describe "Api::V1::PermissionRoles", type: :request do
  let(:admin) { create(:user, user_type: :system_admin, user_must_change_password: false) }
  let(:session_token) do
    _session, raw_token = Session.issue_for(user: admin, mode: :normal)
    raw_token
  end

  describe "GET /api/v1/permission_roles" do
    it "lists permission roles for a system_admin" do
      create(:permission_role, role_name: "スタッフ")

      get "/api/v1/permission_roles", headers: authenticated_headers(session_token)

      expect(response).to have_http_status(:ok)
      expect(json["permission_roles"].map { |role| role["role_name"] }).to include("スタッフ")
    end

    it "is also listable by a non-system_admin (role names aren't sensitive)" do
      create(:permission_role, role_name: "スタッフ")
      general_user = create(:user, user_type: :general, user_must_change_password: false)
      _session, token = Session.issue_for(user: general_user, mode: :normal)

      get "/api/v1/permission_roles", headers: authenticated_headers(token)

      expect(response).to have_http_status(:ok)
      expect(json["permission_roles"].map { |role| role["role_name"] }).to include("スタッフ")
    end
  end

  describe "POST /api/v1/permission_roles" do
    it "creates a permission role and backfills a role_permission row for every existing feature" do
      pm_a = create(:permission_master)
      pm_b = create(:permission_master)

      post "/api/v1/permission_roles", params: { role_name: "スタッフ", role_sort: 1 },
        headers: authenticated_headers(session_token), as: :json

      expect(response).to have_http_status(:created)
      role = PermissionRole.find_by(role_name: "スタッフ")
      expect([ pm_a.pm_id, pm_b.pm_id ].all? { |id| role.role_permissions.exists?(pm_id: id) }).to be true
    end

    it "is forbidden for a non-system_admin" do
      general_user = create(:user, user_type: :general, user_must_change_password: false)
      _session, token = Session.issue_for(user: general_user, mode: :normal)

      post "/api/v1/permission_roles", params: { role_name: "スタッフ" },
        headers: authenticated_headers(token), as: :json

      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "PATCH /api/v1/permission_roles/:id" do
    it "is forbidden for a non-system_admin" do
      role = create(:permission_role)
      general_user = create(:user, user_type: :general, user_must_change_password: false)
      _session, token = Session.issue_for(user: general_user, mode: :normal)

      patch "/api/v1/permission_roles/#{role.role_id}", params: { role_name: "改名" },
        headers: authenticated_headers(token), as: :json

      expect(response).to have_http_status(:forbidden)
      expect(role.reload.role_name).not_to eq("改名")
    end
  end

  describe "DELETE /api/v1/permission_roles/:id" do
    it "destroys the permission role and its role_permissions" do
      role = create(:permission_role)
      rp_ids = role.role_permissions.pluck(:rp_id)

      delete "/api/v1/permission_roles/#{role.role_id}", headers: authenticated_headers(session_token)

      expect(response).to have_http_status(:no_content)
      expect(RolePermission.where(rp_id: rp_ids)).to be_empty
    end

    it "is forbidden for a non-system_admin" do
      role = create(:permission_role)
      general_user = create(:user, user_type: :general, user_must_change_password: false)
      _session, token = Session.issue_for(user: general_user, mode: :normal)

      delete "/api/v1/permission_roles/#{role.role_id}", headers: authenticated_headers(token)

      expect(response).to have_http_status(:forbidden)
      expect(PermissionRole.exists?(role.role_id)).to be true
    end
  end

  def json
    JSON.parse(response.body)
  end
end
