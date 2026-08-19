module Api
  module V1
    module Auth
      # Password/ID login (spec section 3.1). QR login is handled
      # separately by QrSessionsController since it has a different
      # identifier, a different rejection rule (retired users), and issues
      # a differently-scoped session (session_mode: qr_limited).
      class SessionsController < Api::V1::BaseController
        before_action :authenticate_session!, only: %i[show destroy]

        def create
          result = UserAuthenticator.call(identifier: params[:identifier], password: params[:password])
          return render json: { error: result.error }, status: :unauthorized unless result.success?

          session, raw_token = Session.issue_for(
            user: result.user,
            mode: :normal,
            ip_address: request.remote_ip,
            user_agent: request.user_agent
          )
          render json: { session_token: raw_token, user: serialize_user(session.user) }, status: :created
        end

        def show
          render json: { user: serialize_user(current_user), session_mode: current_session.session_mode }
        end

        def destroy
          current_session.destroy!
          head :no_content
        end
      end
    end
  end
end
