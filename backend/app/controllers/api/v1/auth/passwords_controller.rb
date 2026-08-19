module Api
  module V1
    module Auth
      # Handles both the forced first-login reset and any later voluntary
      # password change (spec sections 3.2/13.2). Deliberately does not
      # call enforce_password_reset! — this is the one endpoint that must
      # stay reachable while user_must_change_password is true.
      class PasswordsController < Api::V1::BaseController
        MIN_LENGTH = 4

        before_action :authenticate_session!

        def update
          new_password = params[:password].to_s

          if new_password.length < MIN_LENGTH
            return render json: { error: "password_too_short" }, status: :unprocessable_entity
          end

          current_user.password = new_password
          current_user.user_must_change_password = false
          current_user.save!

          render json: { user: serialize_user(current_user) }
        end
      end
    end
  end
end
