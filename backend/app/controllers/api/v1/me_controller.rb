module Api
  module V1
    # A minimal authenticated endpoint: both the frontend's "who is logged
    # in" check and, for now, the concrete stand-in DoD requires for
    # verifying that no feature is reachable until the forced first-login
    # password reset (see BaseController#enforce_password_reset!) is done.
    class MeController < Api::V1::BaseController
      before_action :authenticate_session!
      before_action :enforce_password_reset!

      def show
        render json: { user: serialize_user(current_user) }
      end
    end
  end
end
