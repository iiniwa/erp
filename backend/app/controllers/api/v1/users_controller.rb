module Api
  module V1
    # Employee CRUD + retirement (spec section 5.1). Access is gated by
    # UserPolicy (t.role_permissions, spec section 4) on top of the
    # session/password-reset checks; require_normal_session! additionally
    # keeps QR-limited sessions out entirely, regardless of role.
    class UsersController < BaseController
      before_action :authenticate_session!
      before_action :enforce_password_reset!
      before_action :require_normal_session!
      before_action :set_user, only: %i[show update destroy retire]

      def index
        authorize User
        users = User.order(:user_code)
        render json: { users: users.map { |user| serialize_employee(user) } }
      end

      def show
        authorize @user
        render json: { user: serialize_employee(@user) }
      end

      # The initial password is the birthdate (spec sections 3.2/13.1),
      # matching the same rule the fixed admin seed follows, so every new
      # employee goes through the same first-login flow.
      def create
        authorize User

        birth = parse_date(params[:user_birth])
        unless birth
          return render json: { error: "user_birth_required" }, status: :unprocessable_entity
        end

        user = User.new(create_params)
        user.user_birth = birth
        user.password = birth.strftime("%Y%m%d")
        user.user_must_change_password = true

        if user.save
          render json: { user: serialize_employee(user) }, status: :created
        else
          render json: { errors: user.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # Deliberately excludes user_type: retirement goes through #retire
      # instead, so a stray edit here can't silently grant/revoke admin.
      def update
        authorize @user

        if @user.update(update_params)
          render json: { user: serialize_employee(@user) }
        else
          render json: { errors: @user.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def destroy
        authorize @user
        return render_system_admin_protected if @user.system_admin?

        @user.soft_delete!
        head :no_content
      end

      # Retirement (user_type: 9) is independent of soft deletion (spec
      # section 5.1): a retired employee still appears in listings and
      # keeps their address book entry. Gated on #update? (it's a profile
      # change, not a delete).
      def retire
        authorize @user, :update?
        return render_system_admin_protected if @user.system_admin?

        @user.update!(user_type: :retired)
        render json: { user: serialize_employee(@user) }
      end

      private

      def set_user
        @user = User.find_by(user_code: params[:user_code])
        render json: { error: "not_found" }, status: :not_found unless @user
      end

      # The fixed system administrator (spec section 13.1) must always
      # have exactly one active, non-retired account, since
      # PermissionMasterPolicy/RolePermissionPolicy hard-code system_admin
      # as the only role that can manage RBAC itself (see
      # ApplicationPolicy's comment). Deleting or retiring that account —
      # even by itself — would permanently lock everyone out of the one
      # screen that could undo it. db/seeds.rb already requires manual
      # restoration for the soft-deleted case; this closes off reaching
      # that state through the API in the first place.
      def render_system_admin_protected
        render json: { error: "system_admin_protected" }, status: :conflict
      end

      def create_params
        params.permit(
          :user_id, :user_type, :role_id, :user_familyname, :user_firstname,
          :user_familyname_ruby, :user_firstname_ruby, :user_join_date
        )
      end

      def update_params
        params.permit(
          :user_id, :role_id, :user_familyname, :user_firstname,
          :user_familyname_ruby, :user_firstname_ruby, :user_join_date
        )
      end

      def parse_date(value)
        Date.parse(value.to_s)
      rescue ArgumentError, TypeError
        nil
      end

      def serialize_employee(user)
        {
          user_code: user.user_code,
          user_id: user.user_id,
          user_type: user.user_type,
          role_id: user.role_id,
          role_name: user.permission_role&.role_name,
          user_familyname: user.user_familyname,
          user_firstname: user.user_firstname,
          user_familyname_ruby: user.user_familyname_ruby,
          user_firstname_ruby: user.user_firstname_ruby,
          user_birth: user.user_birth,
          user_join_date: user.user_join_date,
          user_entry_date: user.user_entry_date,
          user_is_locked: user.user_is_locked,
          user_must_change_password: user.user_must_change_password
        }
      end
    end
  end
end
