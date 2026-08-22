require "net/http"

# Uploads/downloads/deletes files through SFTPGo's end-user REST API
# (spec section 9.1-9.3). SFTPGo does not expose an S3-compatible server
# itself (it can use S3 as a *backend*, which is a different thing), so
# this talks to SFTPGo's own HTTP API instead of aws-sdk-s3.
#
# Authenticates as a dedicated non-admin SFTPGo account (SFTPGO_APP_USER,
# provisioned by `bin/rails sftpgo:provision`) whose files land under
# /general (spec section 9.3's "/files/general/"); "archive" is defined
# for a later phase's t.archive feature and intentionally unused here.
class FileStorageService
  class Error < StandardError; end

  FOLDER_BY_TYPE = { "general" => "general", "archive" => "archive" }.freeze

  def self.upload(...)
    new.upload(...)
  end

  def self.delete(...)
    new.delete(...)
  end

  def self.download(...)
    new.download(...)
  end

  # Returns the object key (e.g. "general/<uuid>-<filename>") to store as
  # StoredFile#file_path.
  def upload(file_type:, filename:, io:, content_type:)
    key = object_key(file_type, filename)
    request = Net::HTTP::Post.new(upload_uri(key))
    request["Authorization"] = "Bearer #{user_token}"
    request["Content-Type"] = content_type.presence || "application/octet-stream"
    request.body = io.read

    response = http.request(request)
    raise Error, "SFTPGo upload failed (#{response.code}): #{response.body}" unless response.is_a?(Net::HTTPSuccess)

    key
  end

  def download(object_key)
    request = Net::HTTP::Get.new(download_uri(object_key))
    request["Authorization"] = "Bearer #{user_token}"

    response = http.request(request)
    raise Error, "SFTPGo download failed (#{response.code}): #{response.body}" unless response.is_a?(Net::HTTPSuccess)

    response.body
  end

  def delete(object_key)
    request = Net::HTTP::Delete.new(download_uri(object_key))
    request["Authorization"] = "Bearer #{user_token}"

    response = http.request(request)
    return if response.is_a?(Net::HTTPSuccess)
    return if response.is_a?(Net::HTTPNotFound)

    raise Error, "SFTPGo delete failed (#{response.code}): #{response.body}"
  end

  private

  def object_key(file_type, filename)
    folder = FOLDER_BY_TYPE.fetch(file_type.to_s) { raise Error, "unknown file_type #{file_type}" }
    "#{folder}/#{SecureRandom.uuid}-#{filename}"
  end

  def upload_uri(key)
    URI("#{base_url}/api/v2/user/files/upload?path=#{ERB::Util.url_encode(key)}&mkdir_parents=true")
  end

  def download_uri(key)
    URI("#{base_url}/api/v2/user/files?path=#{ERB::Util.url_encode(key)}")
  end

  def base_url
    ENV.fetch("SFTPGO_URL", "http://sftpgo:8080")
  end

  def http
    @http ||= Net::HTTP.new(URI(base_url).host, URI(base_url).port)
  end

  # A fresh token per instance (this service is instantiated per call, not
  # cached process-wide) rather than tracking the JWT's expiry: upload
  # volume here is a handful of admin-driven settings-screen actions, not
  # a hot path worth optimizing for round-trip count.
  def user_token
    @user_token ||= begin
      request = Net::HTTP::Get.new("/api/v2/user/token")
      request.basic_auth(ENV.fetch("SFTPGO_APP_USER", "erp_app"), ENV.fetch("SFTPGO_APP_PASSWORD"))
      response = http.request(request)
      unless response.is_a?(Net::HTTPSuccess)
        raise Error, "SFTPGo authentication failed (#{response.code}): #{response.body}"
      end

      JSON.parse(response.body)["access_token"]
    end
  end
end
