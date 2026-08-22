require "rails_helper"

RSpec.describe "Api::V1::SystemSettings", type: :request do
  let(:admin) { create(:user, user_type: :system_admin, user_must_change_password: false) }
  let(:session_token) do
    _session, raw_token = Session.issue_for(user: admin, mode: :normal)
    raw_token
  end

  describe "GET /api/v1/system_setting" do
    it "returns the singleton settings for a system_admin" do
      SystemSetting.instance.update!(company_name: "Iiniwa")

      get "/api/v1/system_setting", headers: authenticated_headers(session_token)

      expect(response).to have_http_status(:ok)
      expect(json["system_setting"]["company_name"]).to eq("Iiniwa")
    end

    it "is forbidden for a non-system_admin" do
      general_user = create(:user, user_type: :general, user_must_change_password: false)
      _session, token = Session.issue_for(user: general_user, mode: :normal)

      get "/api/v1/system_setting", headers: authenticated_headers(token)

      expect(response).to have_http_status(:forbidden)
    end

    it "blocks a QR-limited session regardless of role" do
      _session, token = Session.issue_for(user: admin, mode: :qr_limited)

      get "/api/v1/system_setting", headers: authenticated_headers(token)

      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "PATCH /api/v1/system_setting" do
    it "updates fields and records the updating user" do
      patch "/api/v1/system_setting",
        params: { company_name: "新会社名", login_lockout_count: 5 },
        headers: authenticated_headers(session_token), as: :json

      expect(response).to have_http_status(:ok)
      setting = SystemSetting.instance
      expect(setting.company_name).to eq("新会社名")
      expect(setting.login_lockout_count).to eq(5)
      expect(setting.updated_by).to eq(admin.user_code)
    end

    it "is forbidden for a non-system_admin" do
      general_user = create(:user, user_type: :general, user_must_change_password: false)
      _session, token = Session.issue_for(user: general_user, mode: :normal)

      patch "/api/v1/system_setting", params: { company_name: "新会社名" },
        headers: authenticated_headers(token), as: :json

      expect(response).to have_http_status(:forbidden)
      expect(SystemSetting.instance.company_name).not_to eq("新会社名")
    end

    it "changes login_lockout_count so the lockout threshold used by authentication reflects it" do
      SystemSetting.instance.update!(login_lockout_count: 10)

      patch "/api/v1/system_setting", params: { login_lockout_count: 2 },
        headers: authenticated_headers(session_token), as: :json

      target = create(:user)
      target.register_failed_login!
      expect(target.user_is_locked).to be false
      target.register_failed_login!
      expect(target.user_is_locked).to be true
    end

    it "uploads a logo file, creating a StoredFile and linking it" do
      allow(FileStorageService).to receive(:upload).and_return("general/fake-key-logo.png")
      upload = fixture_file_upload(Rails.root.join("spec/fixtures/files/logo.png"), "image/png")

      patch "/api/v1/system_setting", params: { system_logo_file: upload },
        headers: authenticated_headers(session_token)

      expect(response).to have_http_status(:ok)
      setting = SystemSetting.instance
      expect(setting.system_logo_file).to be_present
      expect(setting.system_logo_file.file_path).to eq("general/fake-key-logo.png")
      expect(FileStorageService).to have_received(:upload).with(
        file_type: "general", filename: "logo.png", io: kind_of(ActionDispatch::Http::UploadedFile),
        content_type: "image/png"
      )
    end

    it "deletes the previous file from storage when replacing it" do
      old_file = create(:stored_file, file_path: "general/old-logo.png")
      SystemSetting.instance.update!(system_logo_file: old_file)
      allow(FileStorageService).to receive(:upload).and_return("general/new-logo.png")
      allow(FileStorageService).to receive(:delete)
      upload = fixture_file_upload(Rails.root.join("spec/fixtures/files/logo.png"), "image/png")

      patch "/api/v1/system_setting", params: { system_logo_file: upload },
        headers: authenticated_headers(session_token)

      expect(response).to have_http_status(:ok)
      expect(FileStorageService).to have_received(:delete).with("general/old-logo.png")
      expect(old_file.reload.soft_deleted?).to be true
    end
  end

  describe "GET /api/v1/system_setting/files/:field" do
    it "streams the file content for a system_admin" do
      stored_file = create(:stored_file, file_path: "general/logo.png", content_type: "image/png")
      SystemSetting.instance.update!(system_logo_file: stored_file)
      allow(FileStorageService).to receive(:download).with("general/logo.png").and_return("binary-content")

      get "/api/v1/system_setting/files/system_logo_file", headers: authenticated_headers(session_token)

      expect(response).to have_http_status(:ok)
      expect(response.body).to eq("binary-content")
      expect(response.content_type).to eq("image/png")
    end

    it "returns 404 when no file is set" do
      get "/api/v1/system_setting/files/system_logo_file", headers: authenticated_headers(session_token)

      expect(response).to have_http_status(:not_found)
    end

    it "returns 404 for an unknown field" do
      get "/api/v1/system_setting/files/not_a_real_field", headers: authenticated_headers(session_token)

      expect(response).to have_http_status(:not_found)
    end
  end

  def json
    JSON.parse(response.body)
  end
end
