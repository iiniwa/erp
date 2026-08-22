require "net/http"

namespace :sftpgo do
  desc "Create (or update) the non-admin SFTPGo account FileStorageService uploads through"
  task provision: :environment do
    base_url = ENV.fetch("SFTPGO_URL", "http://sftpgo:8080")
    admin_user = ENV.fetch("SFTPGO_ADMIN_USER")
    admin_password = ENV.fetch("SFTPGO_ADMIN_PASSWORD")
    app_user = ENV.fetch("SFTPGO_APP_USER", "erp_app")
    app_password = ENV.fetch("SFTPGO_APP_PASSWORD")

    uri = URI(base_url)
    http = Net::HTTP.new(uri.host, uri.port)

    token_request = Net::HTTP::Get.new("/api/v2/token")
    token_request.basic_auth(admin_user, admin_password)
    token_response = http.request(token_request)
    unless token_response.is_a?(Net::HTTPSuccess)
      abort "Failed to authenticate as SFTPGo admin (#{token_response.code}): #{token_response.body}"
    end
    admin_token = JSON.parse(token_response.body)["access_token"]

    check_request = Net::HTTP::Get.new("/api/v2/users/#{app_user}")
    check_request["Authorization"] = "Bearer #{admin_token}"
    check_response = http.request(check_request)

    if check_response.is_a?(Net::HTTPSuccess)
      puts "SFTPGo user #{app_user.inspect} already exists, nothing to do."
      next
    end

    # Denies every protocol except HTTP (the REST "user API" FileStorageService
    # uses): this account exists solely for application uploads, not for
    # someone to log in over SFTP/FTP/WebDAV with.
    create_request = Net::HTTP::Post.new("/api/v2/users")
    create_request["Authorization"] = "Bearer #{admin_token}"
    create_request["Content-Type"] = "application/json"
    create_request.body = {
      username: app_user,
      password: app_password,
      status: 1,
      home_dir: "/srv/sftpgo/data/#{app_user}",
      permissions: { "/" => [ "*" ] },
      filters: { denied_protocols: %w[SSH FTP DAV] }
    }.to_json

    create_response = http.request(create_request)
    unless create_response.is_a?(Net::HTTPSuccess)
      abort "Failed to create SFTPGo user #{app_user.inspect} (#{create_response.code}): #{create_response.body}"
    end

    puts "Created SFTPGo user #{app_user.inspect}."
  end
end
