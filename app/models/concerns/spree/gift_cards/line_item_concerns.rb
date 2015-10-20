module Spree
  module GiftCards::LineItemConcerns
    extend ActiveSupport::Concern

    included do
      has_many :gift_cards, class_name: Spree::VirtualGiftCard, dependent: :destroy
      delegate :gift_card?, :gift_card, to: :product
      prepend(InstanceMethods)
    end

    module InstanceMethods
      def redemption_codes
        gift_cards.map {|gc| {amount: gc.formatted_amount, redemption_code: gc.formatted_redemption_code}}
      end

      def gift_card_details
        gift_cards.map do |gc|
          {
            amount: gc.formatted_amount,
            redemption_code: gc.formatted_redemption_code,
            recipient_email: gc.recipient_email,
            recipient_name: gc.recipient_name,
            purchaser_name: gc.purchaser_name,
            gift_message: gc.gift_message,
          }
        end
      end
    end
  end
end
