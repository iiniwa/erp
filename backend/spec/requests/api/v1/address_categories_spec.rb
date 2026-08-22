require "rails_helper"

RSpec.describe "Api::V1::AddressCategories", type: :request do
  let(:admin) { create(:user, user_must_change_password: false) }
  let(:session_token) do
    _session, raw_token = Session.issue_for(user: admin, mode: :normal)
    raw_token
  end

  before { grant_permission!(admin, "address_book") }

  describe "GET /api/v1/address_categories" do
    it "lists categories ordered by ac_sort" do
      create(:address_category, ac_name: "取引先", ac_sort: 2)
      create(:address_category, ac_name: "社内", ac_sort: 1)

      get "/api/v1/address_categories", headers: authenticated_headers(session_token)

      expect(response).to have_http_status(:ok)
      expect(json["address_categories"].map { |c| c["ac_name"] }).to eq(%w[社内 取引先])
    end

    it "blocks a role with no address_book permission" do
      no_permission_user = create(:user, user_type: :part_time, user_must_change_password: false)
      _session, token = Session.issue_for(user: no_permission_user, mode: :normal)

      get "/api/v1/address_categories", headers: authenticated_headers(token)

      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "POST /api/v1/address_categories" do
    it "creates a category" do
      post "/api/v1/address_categories", params: { ac_name: "個人", ac_sort: 3 },
        headers: authenticated_headers(session_token), as: :json

      expect(response).to have_http_status(:created)
      expect(json["address_category"]["ac_name"]).to eq("個人")
    end

    it "rejects a blank name" do
      post "/api/v1/address_categories", params: { ac_name: "" },
        headers: authenticated_headers(session_token), as: :json

      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  def json
    JSON.parse(response.body)
  end
end
