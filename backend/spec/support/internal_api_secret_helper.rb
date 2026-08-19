module InternalApiSecretHelper
  def internal_api_headers(extra = {})
    { "X-Internal-Api-Secret" => ENV.fetch("INTERNAL_API_SECRET") }.merge(extra)
  end

  def authenticated_headers(token, extra = {})
    internal_api_headers({ "Authorization" => "Bearer #{token}" }.merge(extra))
  end
end

RSpec.configure do |config|
  config.include InternalApiSecretHelper, type: :request
end
