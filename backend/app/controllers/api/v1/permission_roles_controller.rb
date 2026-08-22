module Api
  module V1
    # Freely admin-managed permission levels (spec section 4): unlike
    # PermissionMaster (the fixed set of features), roles here are an open
    # set an admin creates/deletes from the settings screen. Restricted to
    # system_admin directly (see PermissionRolePolicy) rather than the RBAC
    # table itself, to avoid a self-lockout.
    class PermissionRolesController < BaseController
      before_action :authenticate_session!
      before_action :enforce_password_reset!
      before_action :require_normal_session!
      before_action :set_permission_role, only: %i[update destroy]

      def index
        authorize PermissionRole
        render json: { permission_roles: PermissionRole.all.map { |role| serialize(role) } }
      end

      def create
        authorize PermissionRole

        permission_role = PermissionRole.new(permission_role_params)
        if permission_role.save
          render json: { permission_role: serialize(permission_role) }, status: :created
        else
          render json: { errors: permission_role.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def update
        authorize @permission_role

        if @permission_role.update(permission_role_params)
          render json: { permission_role: serialize(@permission_role) }
        else
          render json: { errors: @permission_role.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # Cascades to the role's role_permissions rows (dependent: :destroy)
      # and nullifies role_id on any employee assigned to it (dependent:
      # :nullify), leaving them with no RBAC-governed access rather than
      # blocking the deletion.
      def destroy
        authorize @permission_role
        @permission_role.destroy!
        head :no_content
      end

      private

      def set_permission_role
        @permission_role = PermissionRole.find_by(role_id: params[:id])
        render json: { error: "not_found" }, status: :not_found unless @permission_role
      end

      def permission_role_params
        params.permit(:role_name, :role_sort)
      end

      def serialize(role)
        { role_id: role.role_id, role_name: role.role_name, role_sort: role.role_sort }
      end
    end
  end
end
