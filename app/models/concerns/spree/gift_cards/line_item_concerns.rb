module Spree
  module GiftCards::LineItemConcerns
    extend ActiveSupport::Concern

    included do
      has_many :gift_cards, class_name: Spree::VirtualGiftCard
      delegate :gift_card?, :gift_card, to: :product
      prepend(InstanceMethods)
    end

    module InstanceMethods
      def redemption_codes
        gift_cards.map {|gc| {amount: gc.formatted_amount, redemption_code: gc.formatted_redemption_code}}
      end
    end
  end
end
