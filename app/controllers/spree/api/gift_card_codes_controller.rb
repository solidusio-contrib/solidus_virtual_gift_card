# frozen_string_literal: true

module Spree
  module Api
    class GiftCardCodesController < Spree::Api::BaseController
      before_action :load_order

      def create
        authorize! :update, @order, order_token

        @order.gift_card_codes << params[:gift_card_code].strip

        if @order.save
          respond_with(@order, default_template: 'spree/api/orders/show', status: 201)
        else
          logger.error("apply_gift_card_code_error=#{@order.error.inspect}")
          invalid_resource!(@order)
        end
      end

      def destroy
        authorize! :update, @order, order_token

        @order.gift_card_codes = @order.gift_card_codes - [params[:id]]

        if @order.save
          respond_with(@order, default_template: 'spree/api/orders/show', status: 204)
        else
          logger.error("remove_gift_card_code_error=#{@order.error.inspect}")
          invalid_resource!(@order)
        end
      end

      private

      def load_order
        @order = Spree::Order.find_by!(number: params[:order_id])
      end
    end
  end
end
