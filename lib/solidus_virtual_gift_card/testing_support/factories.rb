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

  factory :virtual_gift_card_event, class: 'Spree::VirtualGiftCardEvent' do
    virtual_gift_card
    amount             { 100.00 }
    authorization_code { "#{virtual_gift_card.id}-GC-20140602164814476128" }
    action               { Spree::VirtualGiftCard::AUTHORIZE_ACTION }

    factory :virtual_gift_card_auth_event, class: 'Spree::VirtualGiftCardEvent' do
      action             { Spree::VirtualGiftCard::AUTHORIZE_ACTION }
    end

    factory :virtual_gift_card_capture_event do
      action             { Spree::VirtualGiftCard::CAPTURE_ACTION }
    end

    factory :virtual_gift_card_adjustment_event do
      action              { Spree::VirtualGiftCard::ADJUSTMENT_ACTION }
    end

    factory :virtual_gift_card_invalidate_event do
      action              { Spree::VirtualGiftCard::INVALIDATE_ACTION }
    end
  end

  factory :gift_card_payment_method, class: 'Spree::PaymentMethod::GiftCard' do
    name          { "Gift Card" }
    description   { "Gift Card" }
    active        { true }
    available_to_admin { false }
    available_to_users { false }
    auto_capture { true }
  end

  factory :gift_card_payment, class: 'Spree::Payment', parent: :payment do
    association(:payment_method, factory: :gift_card_payment_method)
    association(:source, factory: :redeemable_virtual_gift_card)
  end
end
