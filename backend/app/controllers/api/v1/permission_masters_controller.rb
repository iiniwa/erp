module Api
  module V1
    # Feature master (spec section 5.7): the set of screens/features that
    # t.role_permissions grants access to. Restricted to system_admin
    # directly (see PermissionMasterPolicy) rather than the RBAC table
    # itself, to avoid a self-lockout.
    class PermissionMastersController < BaseController
      before_action :authenticate_session!
      before_action :enforce_password_reset!
      before_action :require_normal_session!
      before_action :set_permission_master, only: %i[update destroy]

      def index
        authorize PermissionMaster
        render json: { permission_masters: PermissionMaster.all.map { |pm| serialize(pm) } }
      end

      def create
        authorize PermissionMaster

        permission_master = PermissionMaster.new(permission_master_params)
        if permission_master.save
          render json: { permission_master: serialize(permission_master) }, status: :created
        else
          render json: { errors: permission_master.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def update
        authorize @permission_master

        if @permission_master.update(permission_master_params)
          render json: { permission_master: serialize(@permission_master) }
        else
          render json: { errors: @permission_master.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # Cascades to the feature's role_permissions rows (see
      # PermissionMaster's dependent: :destroy) since those settings have
      # no meaning once the feature itself is gone.
      def destroy
        authorize @permission_master
        @permission_master.destroy!
        head :no_content
      end

      private

      def set_permission_master
        @permission_master = PermissionMaster.find_by(pm_id: params[:id])
        render json: { error: "not_found" }, status: :not_found unless @permission_master
      end

      def permission_master_params
        params.permit(:pm_code, :pm_name, :pm_sort)
      end

      def serialize(pm)
        { pm_id: pm.pm_id, pm_code: pm.pm_code, pm_name: pm.pm_name, pm_sort: pm.pm_sort }
      end
    end
  end
end
