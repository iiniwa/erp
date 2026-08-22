module Api
  module V1
    # The one and only place an employee's address book entry can be
    # created or edited (spec section 5.2's employee<->address linkage
    # must not be changeable from the general address book screen — see
    # Api::V1::AddressesController). Gated by UserPolicy (the same
    # user_manage permission as employee management itself), not
    # AddressPolicy.
    class EmployeeAddressesController < BaseController
      before_action :authenticate_session!
      before_action :enforce_password_reset!
      before_action :require_normal_session!
      before_action :set_user

      def show
        authorize @user
        render json: { address: serialize_address(address) }
      end

      def update
        authorize @user, :update?

        if address.update(address_params)
          render json: { address: serialize_address(address) }
        else
          render json: { errors: address.errors.full_messages }, status: :unprocessable_entity
        end
      end

      private

      def set_user
        # Rails names this "user_user_code" (parent resource's singular
        # name + its :param option), not "user_code".
        @user = User.find_by(user_code: params[:user_user_code])
        render json: { error: "not_found" }, status: :not_found unless @user
      end

      # Lazily provisions the employee's address book entry on first
      # touch rather than requiring a separate "create" step — every
      # employee ends up with exactly one (spec section 5.2), and there's
      # nothing meaningful to configure before tel/email numbers exist.
      def address
        @address ||= Address.find_or_initialize_by(address_user_code: @user.user_code) do |new_address|
          new_address.address_category = in_house_category
          new_address.address_name = "#{@user.user_familyname} #{@user.user_firstname}"
          new_address.address_ruby = "#{@user.user_familyname_ruby}#{@user.user_firstname_ruby}"
        end
      end

      # Matches db/seeds.rb's fixed system administrator address: business
      # contacts get their own category, but there's no meaningful choice
      # to offer for an employee's own entry.
      def in_house_category
        AddressCategory.find_or_create_by!(ac_name: "社内") { |category| category.ac_sort = 1 }
      end

      def address_params
        params.permit(
          :address_contact_name, :address_post, :address_residence, :address_memo,
          address_tels_attributes: %i[id at_number at_label_type at_label_free at_sort is_emergency _destroy],
          address_emails_attributes: %i[id ae_email ae_label ae_sort _destroy]
        )
      end

      def serialize_address(address_record)
        {
          address_id: address_record.address_id,
          address_name: address_record.address_name,
          address_ruby: address_record.address_ruby,
          address_contact_name: address_record.address_contact_name,
          address_post: address_record.address_post,
          address_residence: address_record.address_residence,
          address_memo: address_record.address_memo,
          address_tels: address_record.address_tels.map { |tel| serialize_tel(tel) },
          address_emails: address_record.address_emails.map { |email| serialize_email(email) }
        }
      end

      def serialize_tel(tel)
        {
          at_id: tel.at_id,
          at_number: tel.at_number,
          at_label_type: tel.at_label_type,
          at_label_free: tel.at_label_free,
          at_sort: tel.at_sort,
          is_emergency: tel.is_emergency
        }
      end

      def serialize_email(email)
        { ae_id: email.ae_id, ae_email: email.ae_email, ae_label: email.ae_label, ae_sort: email.ae_sort }
      end
    end
  end
end
