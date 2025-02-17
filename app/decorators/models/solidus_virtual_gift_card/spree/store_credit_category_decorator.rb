# frozen_string_literal: true

module SolidusVirtualGiftCard
  module Spree
    module StoreCreditCategoryDecorator
      def self.prepended(base)
        gift_card_category_name = 'Gift Card'
        base.const_set(:GIFT_CARD_CATEGORY_NAME, gift_card_category_name) unless base.const_defined?(:GIFT_CARD_CATEGORY_NAME)
        base.non_expiring_credit_types |= [gift_card_category_name]
      end

      ::Spree::StoreCreditCategory.prepend self
    end
  end
end
