Rails.application.config.to_prepare do
  Spree::Admin::StoreCreditEventsHelper.originator_links[Spree::VirtualGiftCard.to_s] = {
    new_tab: true,
    href_type: :line_item,
    translation_key: 'admin.gift_cards.gift_card_originator'
  }
end
