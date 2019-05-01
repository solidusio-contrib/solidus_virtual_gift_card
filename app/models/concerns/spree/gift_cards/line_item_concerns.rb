module Spree
  module GiftCards::LineItemConcerns
    extend ActiveSupport::Concern

    included do
      has_many :gift_cards, class_name: 'Spree::VirtualGiftCard', dependent: :destroy
      delegate :gift_card?, :gift_card, to: :product
      self.whitelisted_ransackable_associations += %w[order]
      prepend(InstanceMethods)
    end

    module InstanceMethods
      def redemption_codes
        gift_cards.map {|gc| {amount: gc.formatted_amount, redemption_code: gc.formatted_redemption_code}}
      end

      def gift_card_details
        gift_cards.map(&:details)
      end
    end
  end
end
