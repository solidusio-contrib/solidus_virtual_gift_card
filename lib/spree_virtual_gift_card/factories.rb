# frozen_string_literal: true

FactoryBot.define do
  factory :store_credit_gift_card_category, class: Spree::StoreCreditCategory do
    name { Spree::StoreCreditCategory::GIFT_CARD_CATEGORY_NAME }
  end

  factory :virtual_gift_card, class: Spree::VirtualGiftCard do
    association :line_item, factory: :line_item
    amount { 25.0 }
    currency { 'USD' }
    recipient_name { 'Tom Riddle' }
    recipient_email { 'me@lordvoldemort.com' }

    factory :redeemable_virtual_gift_card do
      association :purchaser, factory: :user
      inventory_unit do |gift_card|
        gift_card.line_item.inventory_units.find{ |iu| iu.gift_card.nil? } ||
          create(:inventory_unit, line_item: gift_card.line_item)
      end

      redeemable { true }

      before(:create) do |gift_card, _evaluator|
        gift_card.redemption_code = gift_card.send(:generate_unique_redemption_code)
      end
    end
  end
end
