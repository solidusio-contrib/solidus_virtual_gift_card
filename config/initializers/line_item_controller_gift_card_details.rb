Rails.application.config.to_prepare do
  Spree::Order.line_item_comparison_hooks.add('gift_card_match')
end
