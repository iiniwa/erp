require "net/http"
require "uri"
require "json"

namespace :sftpgo do
  desc "Create (or update) the non-admin SFTPGo account FileStorageService uploads through"
  # No :environment dependency: this only speaks HTTP to SFTPGo, so it
  # doesn't need Rails/ActiveRecord loaded (and, more importantly, doesn't
  # need a DB connection available) — see docker-compose.yml's
  # sftpgo_provision service, which runs this in its own short-lived
  # container so the SFTPGo admin credentials never sit in the
  # always-running backend service's environment.
  task :provision do
    base_url = ENV.fetch("SFTPGO_URL", "http://sftpgo:8080")
    admin_user = ENV.fetch("SFTPGO_ADMIN_USER")
    admin_password = ENV.fetch("SFTPGO_ADMIN_PASSWORD")
    app_user = ENV.fetch("SFTPGO_APP_USER", "erp_app")
    app_password = ENV.fetch("SFTPGO_APP_PASSWORD")

    uri = URI(base_url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = uri.scheme == "https"

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
    #
    # Permissions are scoped per virtual path rather than granting "*" at
    # the root: "/general" (spec section 9.3's "/files/general/") gets the
    # read/write/delete ops FileStorageService actually needs; "/archive"
    # is listed read-only even though nothing uploads there yet (a later
    # phase's t.archive feature), per spec section 9.3's WORM requirement
    # ("作成のみ可、上書き・削除不可"); the root itself grants nothing so
    # nothing is reachable outside those two prefixes.
    create_request = Net::HTTP::Post.new("/api/v2/users")
    create_request["Authorization"] = "Bearer #{admin_token}"
    create_request["Content-Type"] = "application/json"
    create_request.body = {
      username: app_user,
      password: app_password,
      status: 1,
      home_dir: "/srv/sftpgo/data/#{app_user}",
      permissions: {
        "/" => %w[list],
        "/general" => %w[list download upload overwrite create_dirs delete_files],
        "/archive" => %w[list download]
      },
      filters: { denied_protocols: %w[SSH FTP DAV] }
    }.to_json

    create_response = http.request(create_request)
    unless create_response.is_a?(Net::HTTPSuccess)
      abort "Failed to create SFTPGo user #{app_user.inspect} (#{create_response.code}): #{create_response.body}"
    end

    puts "Created SFTPGo user #{app_user.inspect}."
  end
end
