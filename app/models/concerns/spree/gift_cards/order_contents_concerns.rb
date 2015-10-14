module Spree
  module GiftCards::OrderContentsConcerns
    extend ActiveSupport::Concern

    included do
      prepend(InstanceMethods)
    end

    module InstanceMethods
      def add(variant, quantity = 1, options = {})
        line_item = super
        create_gift_cards(line_item, options[:gift_card_details] || {})
        line_item
      end

      private

      def create_gift_cards(line_item, gift_card_details)
        Spree::VirtualGiftCard.create!(
          amount: line_item.price,
          currency: line_item.currency,
          line_item: line_item,
          recipient_name: gift_card_details[:recipient_name],
          recipient_email: gift_card_details[:recipient_email],
          purchaser_name: gift_card_details[:purchaser_name],
          gift_message: gift_card_details[:gift_message],
        ) if line_item.gift_card?
      end
    end
  end
end

