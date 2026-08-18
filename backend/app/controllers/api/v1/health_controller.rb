module Api
  module V1
    # Unauthenticated on purpose: used by Docker Compose healthchecks.
    class HealthController < ActionController::API
      def show
        render json: { status: "ok" }
      end
    end
  end
end
