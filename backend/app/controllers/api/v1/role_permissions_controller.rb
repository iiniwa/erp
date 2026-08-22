module Api
  module V1
    # Role x feature permission matrix (spec sections 4, 5.8). Every
    # (role, permission_master) cell is guaranteed to exist by
    # PermissionMaster#create_role_permissions_for_every_role and
    # PermissionRole#create_role_permissions_for_every_feature, so #index
    # can just list what's there rather than backfilling gaps.
    class RolePermissionsController < BaseController
      before_action :authenticate_session!
      before_action :enforce_password_reset!
      before_action :require_normal_session!
      before_action :set_role_permission, only: %i[update]

      def index
        authorize RolePermission
        role_permissions = RolePermission.includes(:permission_master, :permission_role).order(:pm_id, :role_id)
        render json: { role_permissions: role_permissions.map { |rp| serialize(rp) } }
      end

      def update
        authorize @role_permission

        if @role_permission.update(role_permission_params)
          render json: { role_permission: serialize(@role_permission) }
        else
          render json: { errors: @role_permission.errors.full_messages }, status: :unprocessable_entity
        end
      end

      private

      def set_role_permission
        @role_permission = RolePermission.find_by(rp_id: params[:id])
        render json: { error: "not_found" }, status: :not_found unless @role_permission
      end

      def role_permission_params
        params.permit(:rp_can_view, :rp_can_create, :rp_can_update, :rp_can_delete)
      end

      def serialize(rp)
        {
          rp_id: rp.rp_id,
          role_id: rp.role_id,
          role_name: rp.permission_role.role_name,
          pm_id: rp.pm_id,
          pm_code: rp.permission_master.pm_code,
          pm_name: rp.permission_master.pm_name,
          rp_can_view: rp.rp_can_view,
          rp_can_create: rp.rp_can_create,
          rp_can_update: rp.rp_can_update,
          rp_can_delete: rp.rp_can_delete
        }
      end
    end
  end
end
