module Api
  module V1
    module Auth
      # QR badge login for the attendance-punch feature (spec section 3.4).
      # The punch feature itself is a later phase; this controller is the
      # foundation that issues session_mode: qr_limited sessions.
      class QrSessionsController < Api::V1::BaseController
        def create
          user = User.authenticate_by_auth_key(params[:auth_key])
          return render_unauthorized unless user
          return render_unauthorized if user.user_is_locked?

          if user.retired?
            user.register_failed_login!
            return render_unauthorized
          end

          user.register_successful_login!
          session, raw_token = Session.issue_for(
            user: user,
            mode: :qr_limited,
            ip_address: request.remote_ip,
            user_agent: request.user_agent
          )
          render json: { session_token: raw_token, user: serialize_user(session.user) }, status: :created
        end
      end
    end
  end
end
