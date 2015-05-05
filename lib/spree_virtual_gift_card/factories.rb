FactoryGirl.define do
  factory :store_credit_gift_card_category, class: Spree::StoreCreditCategory do
    name      Spree::StoreCreditCategory::GIFT_CARD_CATEGORY_NAME
  end

  factory :virtual_gift_card, class: Spree::VirtualGiftCard do
    purchaser   { create(:user) }
    amount      { '25' }
    currency    { 'USD' }
    line_item   { create(:line_item) }
  end
end
