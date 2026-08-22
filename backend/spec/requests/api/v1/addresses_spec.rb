require "rails_helper"

RSpec.describe "Api::V1::Addresses", type: :request do
  let(:admin) { create(:user, user_must_change_password: false) }
  let(:session_token) do
    _session, raw_token = Session.issue_for(user: admin, mode: :normal)
    raw_token
  end
  let(:category) { create(:address_category) }

  before { grant_permission!(admin, "address_book") }

  describe "GET /api/v1/addresses" do
    it "lists addresses with their tels/emails joined, excluding soft-deleted ones" do
      active = create(:address, address_category: category)
      create(:address_tel, address: active, at_number: "09011112222", at_sort: 1)
      create(:address_email, address: active, ae_email: "a@example.com", ae_sort: 1)
      deleted = create(:address, address_category: category)
      deleted.soft_delete!

      get "/api/v1/addresses", headers: authenticated_headers(session_token)

      expect(response).to have_http_status(:ok)
      ids = json["addresses"].map { |a| a["address_id"] }
      expect(ids).to include(active.address_id)
      expect(ids).not_to include(deleted.address_id)

      found = json["addresses"].find { |a| a["address_id"] == active.address_id }
      expect(found["address_tels"].first["at_number"]).to eq("09011112222")
      expect(found["address_emails"].first["ae_email"]).to eq("a@example.com")
    end

    it "still lists an address belonging to a retired employee" do
      user = create(:user, user_type: :retired)
      address = create(:address, address_category: category, user: user)

      get "/api/v1/addresses", headers: authenticated_headers(session_token)

      ids = json["addresses"].map { |a| a["address_id"] }
      expect(ids).to include(address.address_id)
    end

    it "requires an authenticated session" do
      get "/api/v1/addresses", headers: internal_api_headers

      expect(response).to have_http_status(:unauthorized)
    end

    it "blocks a QR-limited session regardless of role permissions" do
      _session, token = Session.issue_for(user: admin, mode: :qr_limited)

      get "/api/v1/addresses", headers: authenticated_headers(token)

      expect(response).to have_http_status(:forbidden)
    end

    it "blocks a role with no address_book permission" do
      no_permission_user = create(:user, user_type: :part_time, user_must_change_password: false)
      _session, token = Session.issue_for(user: no_permission_user, mode: :normal)

      get "/api/v1/addresses", headers: authenticated_headers(token)

      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "GET /api/v1/addresses/:address_id" do
    it "returns the address" do
      address = create(:address, address_category: category)

      get "/api/v1/addresses/#{address.address_id}", headers: authenticated_headers(session_token)

      expect(response).to have_http_status(:ok)
      expect(json["address"]["address_id"]).to eq(address.address_id)
    end

    it "returns 404 for an unknown address_id" do
      get "/api/v1/addresses/nonexistent", headers: authenticated_headers(session_token)

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "POST /api/v1/addresses" do
    let(:valid_params) do
      {
        address_category_id: category.ac_id,
        address_name: "取引先株式会社",
        address_ruby: "とりひきさきかぶしきがいしゃ",
        address_tels_attributes: [ { at_number: "0311112222", at_label_type: "main", at_sort: 1 } ],
        address_emails_attributes: [ { ae_email: "contact@example.com", ae_sort: 1 } ]
      }
    end

    it "creates an address with nested tel/email rows" do
      post "/api/v1/addresses", params: valid_params, headers: authenticated_headers(session_token),
        as: :json

      expect(response).to have_http_status(:created)
      created = Address.find(json["address"]["address_id"])
      expect(created.address_tels.count).to eq(1)
      expect(created.address_emails.count).to eq(1)
    end

    it "ignores address_user_code — linking to an employee only happens via Employee Management" do
      user = create(:user)
      params = valid_params.merge(address_user_code: user.user_code)

      post "/api/v1/addresses", params: params, headers: authenticated_headers(session_token), as: :json

      expect(response).to have_http_status(:created)
      created = Address.find(json["address"]["address_id"])
      expect(created.address_user_code).to be_nil
    end

    it "rejects an emergency-contact tel on a non-employee address" do
      params = valid_params.merge(
        address_tels_attributes: [ { at_number: "0311112222", at_label_type: "main", at_sort: 1, is_emergency: true } ]
      )

      post "/api/v1/addresses", params: params, headers: authenticated_headers(session_token), as: :json

      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "PATCH /api/v1/addresses/:address_id" do
    it "updates fields and replaces nested tels/emails" do
      address = create(:address, address_category: category)
      tel = create(:address_tel, address: address, at_sort: 1)
      email = create(:address_email, address: address, ae_sort: 1)

      patch "/api/v1/addresses/#{address.address_id}", params: {
        address_name: "更新後の名称",
        address_tels_attributes: [ { id: tel.at_id, at_number: "08099998888" } ],
        address_emails_attributes: [ { id: email.ae_id, _destroy: true } ]
      }, headers: authenticated_headers(session_token), as: :json

      expect(response).to have_http_status(:ok)
      expect(address.reload.address_name).to eq("更新後の名称")
      expect(tel.reload.at_number).to eq("08099998888")
      expect(AddressEmail.exists?(email.ae_id)).to be false
    end

    it "promotes the next email to sort=1 when the primary is deleted" do
      address = create(:address, address_category: category)
      primary = create(:address_email, address: address, ae_email: "a@example.com", ae_sort: 1)
      secondary = create(:address_email, address: address, ae_email: "b@example.com", ae_sort: 2)

      patch "/api/v1/addresses/#{address.address_id}", params: {
        address_emails_attributes: [ { id: primary.ae_id, _destroy: true } ]
      }, headers: authenticated_headers(session_token), as: :json

      expect(response).to have_http_status(:ok)
      expect(secondary.reload.ae_sort).to eq(1)
    end

    it "is forbidden for an employee-linked address — must be edited via Employee Management" do
      user = create(:user)
      address = create(:address, address_category: category, user: user)

      patch "/api/v1/addresses/#{address.address_id}", params: { address_name: "勝手に変更" },
        headers: authenticated_headers(session_token), as: :json

      expect(response).to have_http_status(:forbidden)
      expect(address.reload.address_name).not_to eq("勝手に変更")
    end
  end

  describe "DELETE /api/v1/addresses/:address_id" do
    it "soft-deletes the address" do
      address = create(:address, address_category: category)

      delete "/api/v1/addresses/#{address.address_id}", headers: authenticated_headers(session_token)

      expect(response).to have_http_status(:no_content)
      expect(Address.exists?(address.address_id)).to be false
      expect(Address.with_deleted.exists?(address.address_id)).to be true
    end

    it "is forbidden for an employee-linked address" do
      user = create(:user)
      address = create(:address, address_category: category, user: user)

      delete "/api/v1/addresses/#{address.address_id}", headers: authenticated_headers(session_token)

      expect(response).to have_http_status(:forbidden)
      expect(Address.exists?(address.address_id)).to be true
    end
  end

  def json
    JSON.parse(response.body)
  end
end
