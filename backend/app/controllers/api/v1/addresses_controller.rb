module Api
  module V1
    # Address book CRUD (spec sections 5.2-5.5). Search (section 6) is
    # implemented client-side against the full #index payload, so #index
    # eager-loads tels/emails rather than paginating.
    class AddressesController < BaseController
      before_action :authenticate_session!
      before_action :enforce_password_reset!
      before_action :set_address, only: %i[show update destroy]

      def index
        addresses = Address.includes(:address_category, :address_tels, :address_emails).order(:address_id)
        render json: { addresses: addresses.map { |address| serialize_address(address) } }
      end

      def show
        render json: { address: serialize_address(@address) }
      end

      def create
        address = Address.new(address_params)
        if address.save
          render json: { address: serialize_address(address) }, status: :created
        else
          render json: { errors: address.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def update
        if @address.update(address_params)
          render json: { address: serialize_address(@address) }
        else
          render json: { errors: @address.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # Addresses are never soft-deleted for employees who retire (spec
      # section 5.2), but this action is for genuinely removing a business
      # contact entry; SoftDeletable's default_scope keeps it out of #index.
      def destroy
        @address.soft_delete!
        head :no_content
      end

      private

      def set_address
        @address = Address.find_by(address_id: params[:address_id])
        render json: { error: "not_found" }, status: :not_found unless @address
      end

      def address_params
        params.permit(
          :address_category_id, :address_name, :address_ruby, :address_user_code,
          :address_contact_name, :address_post, :address_residence, :address_memo,
          address_tels_attributes: %i[id at_number at_label_type at_label_free at_sort _destroy],
          address_emails_attributes: %i[id ae_email ae_label ae_sort _destroy]
        )
      end

      def serialize_address(address)
        {
          address_id: address.address_id,
          address_category_id: address.address_category_id,
          address_category_name: address.address_category.ac_name,
          address_name: address.address_name,
          address_ruby: address.address_ruby,
          address_user_code: address.address_user_code,
          address_contact_name: address.address_contact_name,
          address_post: address.address_post,
          address_residence: address.address_residence,
          address_memo: address.address_memo,
          address_tels: address.address_tels.map { |tel| serialize_tel(tel) },
          address_emails: address.address_emails.map { |email| serialize_email(email) }
        }
      end

      def serialize_tel(tel)
        {
          at_id: tel.at_id,
          at_number: tel.at_number,
          at_label_type: tel.at_label_type,
          at_label_free: tel.at_label_free,
          at_sort: tel.at_sort
        }
      end

      def serialize_email(email)
        { ae_id: email.ae_id, ae_email: email.ae_email, ae_label: email.ae_label, ae_sort: email.ae_sort }
      end
    end
  end
end
