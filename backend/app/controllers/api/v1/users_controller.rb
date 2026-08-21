module Api
  module V1
    # Employee CRUD + retirement (spec section 5.1). Permission checks
    # (Issue #6 RBAC) are not wired in yet, per Issue #4's scope; only
    # "must be logged in and have finished the forced password reset"
    # applies for now.
    class UsersController < BaseController
      before_action :authenticate_session!
      before_action :enforce_password_reset!
      before_action :set_user, only: %i[show update destroy retire]

      def index
        users = User.order(:user_code)
        render json: { users: users.map { |user| serialize_employee(user) } }
      end

      def show
        render json: { user: serialize_employee(@user) }
      end

      # The initial password is the birthdate (spec sections 3.2/13.1),
      # matching the same rule the fixed admin seed follows, so every new
      # employee goes through the same first-login flow.
      def create
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
        if @user.update(update_params)
          render json: { user: serialize_employee(@user) }
        else
          render json: { errors: @user.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def destroy
        @user.soft_delete!
        head :no_content
      end

      # Retirement (user_type: 9) is independent of soft deletion (spec
      # section 5.1): a retired employee still appears in listings and
      # keeps their address book entry.
      def retire
        @user.update!(user_type: :retired)
        render json: { user: serialize_employee(@user) }
      end

      private

      def set_user
        @user = User.find_by(user_code: params[:user_code])
        render json: { error: "not_found" }, status: :not_found unless @user
      end

      def create_params
        params.permit(
          :user_id, :user_type, :user_familyname, :user_firstname,
          :user_familyname_ruby, :user_firstname_ruby, :user_join_date
        )
      end

      def update_params
        params.permit(
          :user_id, :user_familyname, :user_firstname,
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
