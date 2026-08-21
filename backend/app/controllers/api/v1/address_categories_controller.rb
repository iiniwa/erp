module Api
  module V1
    # Category master for the address book (spec section 5.3). No seed
    # data by policy; categories are registered ad hoc as needed, so only
    # the minimal index/create are exposed for now. Gated by the same
    # "address_book" permission as AddressPolicy (see
    # AddressCategoryPolicy) rather than its own pm_code, since this is
    # picklist maintenance for the address book form, not a standalone
    # feature; require_normal_session! keeps QR-limited sessions out
    # entirely, same as every other office feature (spec section 4).
    class AddressCategoriesController < BaseController
      before_action :authenticate_session!
      before_action :enforce_password_reset!
      before_action :require_normal_session!

      def index
        authorize AddressCategory
        render json: { address_categories: AddressCategory.order(:ac_sort).map { |category| serialize(category) } }
      end

      def create
        authorize AddressCategory

        category = AddressCategory.new(category_params)
        if category.save
          render json: { address_category: serialize(category) }, status: :created
        else
          render json: { errors: category.errors.full_messages }, status: :unprocessable_entity
        end
      end

      private

      def category_params
        params.permit(:ac_name, :ac_sort)
      end

      def serialize(category)
        { ac_id: category.ac_id, ac_name: category.ac_name, ac_sort: category.ac_sort }
      end
    end
  end
end
