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

      def render_unauthorized(error = "unauthorized")
        render json: { error: error }, status: :unauthorized
      end

      # Opt-in via `before_action :authenticate_session!` in controllers
      # that require a logged-in user (session/qr_session#create do not,
      # since there is no session yet at that point).
      def authenticate_session!
        @current_session = Session.authenticate(bearer_token)
        render_unauthorized unless @current_session
      end

      # Opt-in, and only after authenticate_session!: blocks access until
      # the forced first-login password reset is done (spec section 3.2).
      # Api::V1::Auth::PasswordsController deliberately does not use this,
      # since it's the one endpoint that must stay reachable.
      def enforce_password_reset!
        return unless current_user&.user_must_change_password?

        render json: { error: "password_reset_required" }, status: :forbidden
      end

      # Opt-in: rejects QR-limited sessions (spec sections 3.4/4.3). Actual
      # attendance-punch endpoints that QR mode *should* reach belong to a
      # later phase; this is the enforcement point they'll opt out of.
      def require_normal_session!
        return if current_session&.normal?

        render_forbidden
      end

      def current_session
        @current_session
      end

      def current_user
        current_session&.user
      end

      def bearer_token
        header = request.headers["Authorization"]
        header&.start_with?("Bearer ") ? header.delete_prefix("Bearer ") : nil
      end

      def serialize_user(user)
        {
          user_code: user.user_code,
          user_id: user.user_id,
          user_type: user.user_type,
          role_id: user.role_id,
          role_name: user.permission_role&.role_name,
          user_familyname: user.user_familyname,
          user_firstname: user.user_firstname,
          user_must_change_password: user.user_must_change_password,
          permissions: permissions_for(user)
        }
      end

      # Lets the frontend hide/show actions it has no access to without
      # guessing at the RBAC rules; the backend's Pundit policies remain
      # the actual enforcement point regardless of what the UI shows.
      # system_admin always has full access (see ApplicationPolicy) so it
      # is reported as such here regardless of role_id assignment.
      def permissions_for(user)
        if user.system_admin?
          return PermissionMaster.all.each_with_object({}) do |pm, memo|
            memo[pm.pm_code] = { view: true, create: true, update: true, delete: true }
          end
        end

        return {} unless user.role_id

        RolePermission.includes(:permission_master)
          .where(role_id: user.role_id)
          .each_with_object({}) do |rp, memo|
            memo[rp.permission_master.pm_code] = {
              view: rp.rp_can_view,
              create: rp.rp_can_create,
              update: rp.rp_can_update,
              delete: rp.rp_can_delete
            }
          end
      end
    end
  end
end
