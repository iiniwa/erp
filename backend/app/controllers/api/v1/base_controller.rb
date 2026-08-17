module Api
  module V1
    class BaseController < ActionController::API
      include Pundit::Authorization

      before_action :authenticate_internal_request!

      rescue_from Pundit::NotAuthorizedError, with: :render_forbidden

      private

      # Next.js (BFF層) からのリクエストのみを受け付ける内部シークレット認証。
      # ブラウザから直接Railsを叩かせないための最低限のガード（多重防御の一環）。
      def authenticate_internal_request!
        provided = request.headers["X-Internal-Api-Secret"]
        expected = Rails.application.credentials.internal_api_secret || ENV["INTERNAL_API_SECRET"]

        return if expected.present? && ActiveSupport::SecurityUtils.secure_compare(provided.to_s, expected)

        render json: { error: "unauthorized" }, status: :unauthorized
      end

      def render_forbidden
        render json: { error: "forbidden" }, status: :forbidden
      end
    end
  end
end
