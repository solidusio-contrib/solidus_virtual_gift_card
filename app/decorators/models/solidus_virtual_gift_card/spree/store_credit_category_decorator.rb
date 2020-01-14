# frozen_string_literal: true

Spree::StoreCreditCategory::GIFT_CARD_CATEGORY_NAME = 'Gift Card'
Spree::StoreCreditCategory.non_expiring_credit_types |= [Spree::StoreCreditCategory::GIFT_CARD_CATEGORY_NAME]
