Rails.application.config.to_prepare do
  Spree::Api::LineItemsController.line_item_options += [gift_card_details: [:recipient_name, :recipient_email, :gift_message, :purchaser_name, :send_email_at]]
  Spree::Order.line_item_comparison_hooks.add('gift_card_match')
end
