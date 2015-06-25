FactoryGirl.define do
  factory :store_credit_gift_card_category, class: Spree::StoreCreditCategory do
    name Spree::StoreCreditCategory::GIFT_CARD_CATEGORY_NAME
  end

  factory :virtual_gift_card, class: Spree::VirtualGiftCard do
    association :purchaser, factory: :user
    association :line_item, factory: :line_item

    amount 25.0
    currency "USD"
  end
end
