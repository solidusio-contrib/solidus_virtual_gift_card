module SpreeVirtualGiftCard::StoreCreditCategoryDecorator
  GIFT_CARD_CATEGORY_NAME = 'Gift Card'

  def non_expiring_credit_types
    [GIFT_CARD_CATEGORY_NAME] | super
  end
end
