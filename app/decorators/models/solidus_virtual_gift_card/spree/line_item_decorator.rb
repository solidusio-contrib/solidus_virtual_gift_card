# frozen_string_literal: true

module SolidusVirtualGiftCard
  module Spree
    module LineItemDecorator
      def self.prepended(base)
        base.class_eval do
          has_many :gift_cards, class_name: 'Spree::VirtualGiftCard', dependent: :destroy
          delegate :gift_card?, :gift_card, to: :product
        end
      end

      def redemption_codes
        gift_cards.map { |gc| { amount: gc.formatted_amount, redemption_code: gc.formatted_redemption_code } }
      end

      def gift_card_details
        gift_cards.map(&:details)
      end

      def self.ransackable_associations(auth_object = nil)
        super + %w[order]
      end

      ::Spree::LineItem.prepend self
    end
  end
end
