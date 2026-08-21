module Api
  module V1
    # Category master for the address book (spec section 5.3). No seed
    # data by policy; categories are registered ad hoc as needed, so only
    # the minimal index/create are exposed for now.
    class AddressCategoriesController < BaseController
      before_action :authenticate_session!
      before_action :enforce_password_reset!

      def index
        render json: { address_categories: AddressCategory.order(:ac_sort).map { |category| serialize(category) } }
      end

      def create
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
