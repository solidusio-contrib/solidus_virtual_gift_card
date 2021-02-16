# frozen_string_literal: true

module SolidusVirtualGiftCard
  module Spree
    module StoreCreditCategoryDecorator
      GIFT_CARD_CATEGORY_NAME = 'Gift Card'

      def self.prepended(base)
        base.non_expiring_credit_types |= [GIFT_CARD_CATEGORY_NAME]
      end

      ::Spree::StoreCreditCategory.prepend self
    end
  end
end
