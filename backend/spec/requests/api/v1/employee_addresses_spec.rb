require "rails_helper"

RSpec.describe "Api::V1::EmployeeAddresses", type: :request do
  let(:admin) { create(:user, user_must_change_password: false) }
  let(:session_token) do
    _session, raw_token = Session.issue_for(user: admin, mode: :normal)
    raw_token
  end

  before { grant_permission!(admin, "user_manage") }

  describe "GET /api/v1/users/:user_code/address" do
    it "returns an unsaved default entry when the employee has no address yet" do
      employee = create(:user)

      get "/api/v1/users/#{employee.user_code}/address", headers: authenticated_headers(session_token)

      expect(response).to have_http_status(:ok)
      expect(json["address"]["address_name"]).to eq("#{employee.user_familyname} #{employee.user_firstname}")
      expect(Address.exists?(address_user_code: employee.user_code)).to be false
    end

    it "returns the employee's existing address" do
      employee = create(:user)
      address = create(:address, user: employee, address_contact_name: "既存")

      get "/api/v1/users/#{employee.user_code}/address", headers: authenticated_headers(session_token)

      expect(response).to have_http_status(:ok)
      expect(json["address"]["address_id"]).to eq(address.address_id)
      expect(json["address"]["address_contact_name"]).to eq("既存")
    end

    it "is forbidden for a role with no user_manage permission" do
      employee = create(:user)
      no_permission_user = create(:user, user_type: :part_time, user_must_change_password: false)
      _session, token = Session.issue_for(user: no_permission_user, mode: :normal)

      get "/api/v1/users/#{employee.user_code}/address", headers: authenticated_headers(token)

      expect(response).to have_http_status(:forbidden)
    end

    it "blocks a QR-limited session regardless of role" do
      employee = create(:user)
      _session, token = Session.issue_for(user: admin, mode: :qr_limited)

      get "/api/v1/users/#{employee.user_code}/address", headers: authenticated_headers(token)

      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "PATCH /api/v1/users/:user_code/address" do
    it "creates the address on first save, under the fixed in-house category" do
      employee = create(:user)

      patch "/api/v1/users/#{employee.user_code}/address",
        params: {
          address_tels_attributes: [ { at_number: "09011112222", at_label_type: "mobile", at_sort: 1 } ]
        }, headers: authenticated_headers(session_token), as: :json

      expect(response).to have_http_status(:ok)
      address = Address.find_by(address_user_code: employee.user_code)
      expect(address).to be_present
      expect(address.address_category.ac_name).to eq("社内")
      expect(address.address_tels.sole.at_number).to eq("09011112222")
    end

    it "reuses the same address on subsequent updates rather than creating a second one" do
      employee = create(:user)
      first_address = create(:address, user: employee)

      patch "/api/v1/users/#{employee.user_code}/address", params: { address_contact_name: "担当太郎" },
        headers: authenticated_headers(session_token), as: :json

      expect(response).to have_http_status(:ok)
      expect(Address.where(address_user_code: employee.user_code).count).to eq(1)
      expect(first_address.reload.address_contact_name).to eq("担当太郎")
    end

    it "rejects a primary tel that is not mobile" do
      employee = create(:user)

      patch "/api/v1/users/#{employee.user_code}/address",
        params: { address_tels_attributes: [ { at_number: "0311112222", at_label_type: "main", at_sort: 1 } ] },
        headers: authenticated_headers(session_token), as: :json

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "accepts an emergency contact since the address is employee-linked" do
      employee = create(:user)

      patch "/api/v1/users/#{employee.user_code}/address",
        params: {
          address_tels_attributes: [
            { at_number: "09011112222", at_label_type: "mobile", at_sort: 1 },
            { at_number: "0311112222", at_label_type: "home", at_sort: 2, is_emergency: true }
          ]
        }, headers: authenticated_headers(session_token), as: :json

      expect(response).to have_http_status(:ok)
      address = Address.find_by(address_user_code: employee.user_code)
      expect(address.address_tels.find_by(is_emergency: true).at_number).to eq("0311112222")
    end

    it "rejects destroying the primary mobile tel when a non-mobile tel would become primary" do
      employee = create(:user)
      address = create(:address, user: employee)
      mobile = create(:address_tel, address: address, at_label_type: :mobile, at_sort: 1)
      create(:address_tel, address: address, at_label_type: :main, at_sort: 2)

      patch "/api/v1/users/#{employee.user_code}/address",
        params: { address_tels_attributes: [ { id: mobile.at_id, _destroy: true } ] },
        headers: authenticated_headers(session_token), as: :json

      expect(response).to have_http_status(:unprocessable_entity)
      expect(AddressTel.exists?(mobile.at_id)).to be true
    end

    it "does not accept address_user_code — the linkage always matches the URL's employee" do
      employee = create(:user)
      other_employee = create(:user)

      patch "/api/v1/users/#{employee.user_code}/address",
        params: { address_user_code: other_employee.user_code, address_contact_name: "x" },
        headers: authenticated_headers(session_token), as: :json

      expect(response).to have_http_status(:ok)
      expect(Address.find_by(address_user_code: employee.user_code)).to be_present
      expect(Address.find_by(address_user_code: other_employee.user_code)).to be_nil
    end

    it "is forbidden for a role with no user_manage permission" do
      employee = create(:user)
      no_permission_user = create(:user, user_type: :part_time, user_must_change_password: false)
      _session, token = Session.issue_for(user: no_permission_user, mode: :normal)

      patch "/api/v1/users/#{employee.user_code}/address", params: { address_contact_name: "x" },
        headers: authenticated_headers(token), as: :json

      expect(response).to have_http_status(:forbidden)
    end
  end

  def json
    JSON.parse(response.body)
  end
end
